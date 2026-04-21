import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_sponsors_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_leader_board_model.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/network/dio_client.dart';

class IptTournamentController extends GetxController with GetSingleTickerProviderStateMixin {
  final RxInt selectedTab = 0.obs;
  final RxBool isRefreshingTab = false.obs;
  final RxBool isInitialLoading = true.obs;

  void setSelectedTab(int index) async {
    selectedTab.value = index;
    isRefreshingTab.value = true;
    
    if (index == 0) {
      // Matches tab - refresh match data
      await Future.wait([
        fetchUpcomingMatches(),
        fetchResultMatches(),
        fetchSponsors(),
      ]);
      matchTab.value = 0;
      tabController.animateTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageController.hasClients) pageController.jumpToPage(0);
      });
    } else if (index == 1) {
      // Fixture's tab - refresh leaderboard
      await Future.wait([
        fetchLeaderBoard(),
        fetchLeaderboardUpcomingMatches(),
        fetchSponsors(),
      ]);
    }
    
    isRefreshingTab.value = false;
  }
  final RxInt matchTab = 0.obs; // 0: Upcoming (includes live), 1: Results
  late PageController pageController;
  late TabController tabController;
  
  final LeagueRepository _leagueRepository = LeagueRepository();
  final Rx<GetAllScheduleLiveMatchesModel?> upcomingMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingUpcomingMatches = false.obs;
  final Rx<GetAllScheduleLiveMatchesModel?> resultMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingResultMatches = false.obs;
  final Rx<GetLeagueSponsorsModel?> sponsors = Rx<GetLeagueSponsorsModel?>(null);
  final RxBool isLoadingSponsors = false.obs;
  final Rx<GetLeagueLeaderBoardModel?> leaderBoard = Rx<GetLeagueLeaderBoardModel?>(null);
  final RxBool isLoadingLeaderBoard = false.obs;
  final RxList<String> allCategories = <String>[].obs;
  
  // Upcoming matches for LeaderBoard (Fixture's tab)
  final Rx<GetAllScheduleLiveMatchesModel?> leaderboardUpcomingMatches = Rx<GetAllScheduleLiveMatchesModel?>(null);
  final RxBool isLoadingLeaderboardUpcoming = false.obs;
  
  // Live match scoreboard data
  final Rx<Map<String, dynamic>?> liveMatchScoreboard = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoadingScoreboard = false.obs;
  
  // Socket connection
  IO.Socket? _socket;
  final RxBool isSocketConnected = false.obs;
  final RxBool _socketInitialized = false.obs;
  
  // Carousel for live matches
  final RxInt currentLiveMatchIndex = 0.obs;
  late PageController liveMatchCarouselController;
  
  String? leagueId;

  @override
  void onInit() {
    super.onInit();
    // Get leagueId from arguments
    leagueId = Get.arguments?['leagueId'];
    final matchId = Get.arguments?['matchId'];
    print('🎯 League Controller - Received leagueId: $leagueId, matchId: $matchId');
    
    pageController = PageController(initialPage: 0);
    tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    liveMatchCarouselController = PageController(initialPage: 0);
    
    _loadInitialData();
    
    // Fetch scoreboard data after upcoming matches are loaded (only once)
    ever(upcomingMatches, (matches) {
      if (matches?.data?.isNotEmpty == true && !_socketInitialized.value) {
        final hasLiveMatch = matches!.data!.any((data) => data.matchStatus == 'live');
        if (hasLiveMatch) {
          _initializeLiveMatch(matchId);
        }
      }
    });
  }
  
  void _initializeLiveMatch(String? matchId) {
    if (_socketInitialized.value) return;
    
    final matches = upcomingMatches.value;
    if (matches?.data?.isEmpty ?? true) return;
    
    final liveMatches = matches!.data!.where((data) => data.matchStatus == 'live').toList();
    if (liveMatches.isEmpty) return;
    
    // Set carousel to specific match if matchId provided
    if (matchId != null && matchId.isNotEmpty) {
      final matchIndex = liveMatches.indexWhere((data) => data.matchId?.id == matchId);
      print('🎯 League Controller - Found matchIndex: $matchIndex for matchId: $matchId');
      if (matchIndex != -1) {
        currentLiveMatchIndex.value = matchIndex;
        print('🎯 League Controller - Setting carousel to index: $matchIndex');
        
        // Try multiple times with delays to ensure PageView is ready
        _jumpToCarouselPage(matchIndex, attempts: 5);
      }
    }
    
    fetchLiveMatchScoreboard();
    _connectWebSocket();
    _socketInitialized.value = true;
  }
  
  void _jumpToCarouselPage(int index, {int attempts = 5}) {
    if (attempts <= 0) {
      print('❌ League Controller - Failed to jump carousel after multiple attempts');
      return;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (liveMatchCarouselController.hasClients) {
        print('✅ League Controller - Jumping carousel to page: $index');
        liveMatchCarouselController.jumpToPage(index);
      } else {
        print('⏳ League Controller - PageController not ready, retrying... (attempts left: ${attempts - 1})');
        await Future.delayed(Duration(milliseconds: 100));
        _jumpToCarouselPage(index, attempts: attempts - 1);
      }
    });
  }
  
  Future<void> _loadInitialData() async {
    isInitialLoading.value = true;
    await Future.wait([
      fetchUpcomingMatches(),
      fetchResultMatches(),
      fetchSponsors(),
      fetchLeaderBoard(),
      fetchLeaderboardUpcomingMatches(),
    ]);
    isInitialLoading.value = false;
    
    // Check if we need to initialize live match after data is loaded
    final matchId = Get.arguments?['matchId'];
    if (matchId != null && matchId.isNotEmpty) {
      _initializeLiveMatch(matchId);
    }
  }

  @override
  void onClose() {
    _disconnectWebSocket();
    _socketInitialized.value = false;
    pageController.dispose();
    tabController.dispose();
    liveMatchCarouselController.dispose();
    super.onClose();
  }
  
  void onLiveMatchCarouselChanged(int index) {
    currentLiveMatchIndex.value = index;
    _disconnectWebSocket();
    fetchLiveMatchScoreboard();
    _connectWebSocket();
  }

  void onTabChanged(int index) {
    matchTab.value = index;
    final currentPage = (pageController.hasClients ? pageController.page : null)?.round() ?? pageController.initialPage;
    final distance = (currentPage - index).abs();

    // When moving 0 -> 2 (or 2 -> 0), `animateToPage` scrolls through page 1,
    // which briefly shows the "Live" page. Jump for non-adjacent transitions.
    if (distance > 1) {
      pageController.jumpToPage(index);
    } else {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void onPageChanged(int index) {
    matchTab.value = index;
    tabController.animateTo(index);
  }

  Future<void> fetchUpcomingMatches() async {
    try {
      isLoadingUpcomingMatches.value = true;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        leagueId: leagueId ?? '',
      );
      upcomingMatches.value = response;
    } catch (e) {
      print('Error fetching upcoming matches: $e');
    } finally {
      isLoadingUpcomingMatches.value = false;
    }
  }

  Future<void> fetchResultMatches() async {
    try {
      isLoadingResultMatches.value = true;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'finished',
        leagueId: leagueId ?? '',
      );
      resultMatches.value = response;
    } catch (e) {
      print('Error fetching result matches: $e');
    } finally {
      isLoadingResultMatches.value = false;
    }
  }

  Future<void> fetchSponsors() async {
    try {
      isLoadingSponsors.value = true;
      final response = await _leagueRepository.getLeagueSponsors(leagueId: leagueId);
      print('🎯 Sponsors - leagueId: $leagueId, data: ${response.data?.titleSponsor?.titleSponsorBanner}, sponsors count: ${response.data?.sponsors?.length}');
      sponsors.value = response;
    } catch (e) {
      print('Error fetching sponsors: $e');
    } finally {
      isLoadingSponsors.value = false;
    }
  }

  Future<void> fetchLeaderBoard() async {
    try {
      isLoadingLeaderBoard.value = true;
      final response = await _leagueRepository.getLeagueLeaderBoard(
        leagueId: leagueId ?? '',
      );
      leaderBoard.value = response;
      _extractAllCategories();
    } catch (e) {
      print('Error fetching leaderboard: $e');
    } finally {
      isLoadingLeaderBoard.value = false;
    }
  }
  
  Future<void> fetchLeaderboardUpcomingMatches() async {
    try {
      isLoadingLeaderboardUpcoming.value = true;
      final response = await _leagueRepository.getAllScheduleLiveMatches(
        matchStatus: 'upcoming',
        leagueId: leagueId ?? '',
      );
      leaderboardUpcomingMatches.value = response;
    } catch (e) {
      print('Error fetching leaderboard upcoming matches: $e');
    } finally {
      isLoadingLeaderboardUpcoming.value = false;
    }
  }
  
  void _extractAllCategories() {
    final Set<String> categories = {};
    final standings = leaderBoard.value?.data?.standings ?? [];
    for (var standing in standings) {
      if (standing.categoryWins != null) {
        categories.addAll(standing.categoryWins!.keys);
      }
    }
    allCategories.value = categories.toList();
  }
  
  Future<void> fetchLiveMatchScoreboard() async {
    try {
      // Prevent multiple simultaneous calls
      if (isLoadingScoreboard.value) return;
      
      isLoadingScoreboard.value = true;
      
      // Get the current live match from carousel index
      final allMatches = upcomingMatches.value?.data;
      final liveMatchData = allMatches?.where((data) => data.matchStatus == 'live').toList();
      if (liveMatchData != null && liveMatchData.isNotEmpty) {
        final currentIndex = currentLiveMatchIndex.value < liveMatchData.length ? currentLiveMatchIndex.value : 0;
        final currentLiveMatch = liveMatchData[currentIndex];
        final matchId = currentLiveMatch.matchId?.id;
        
        if (matchId != null && matchId.isNotEmpty) {
          print('📊 Fetching scoreboard for matchId: $matchId');
          // Fetch detailed match history for scoreboard data
          final response = await _leagueRepository.getLeagueMatchDetails(
            matchId: matchId,
            type: 'history',
          );
          
          if (response.history != null) {
            final history = response.history!;
            
            // Extract team data from live match
            final match = currentLiveMatch.matches?.first;
            final teamAPlayers = match?.teamA?.players ?? [];
            final teamBPlayers = match?.teamB?.players ?? [];
            
            // Get all sets data to extract final scores
            final sets = history.sets ?? [];
            
            // Extract final scores from completed sets
            List<String> teamASetScores = [];
            List<String> teamBSetScores = [];
            
            for (var set in sets) {
              final rounds = set.rounds ?? [];
              if (rounds.isNotEmpty) {
                // Get the last round's score as the final score for this set
                final lastRound = rounds.last;
                final teamAScore = lastRound.score?.teamA?.toString() ?? '0';
                final teamBScore = lastRound.score?.teamB?.toString() ?? '0';
                
                teamASetScores.add(teamAScore);
                teamBSetScores.add(teamBScore);
              }
            }
            
            liveMatchScoreboard.value = {
              'teamA': {
                'players': teamAPlayers.map((player) => {
                  'playerName': player.playerName ?? '',
                  'playerId': player.playerId ?? '',
                }).toList(),
                'currentPoints': history.currentPoints?.teamA ?? '0',
                'setsWon': history.setsWon?.teamA ?? 0,
                'roundScores': teamASetScores, // Set final scores instead of round scores
                'totalRounds': teamASetScores.length, // Total sets played
                'logo': match?.teamA?.clubId?.logo ?? '',
              },
              'teamB': {
                'players': teamBPlayers.map((player) => {
                  'playerName': player.playerName ?? '',
                  'playerId': player.playerId ?? '',
                }).toList(),
                'currentPoints': history.currentPoints?.teamB ?? '0',
                'setsWon': history.setsWon?.teamB ?? 0,
                'roundScores': teamBSetScores, // Set final scores instead of round scores
                'totalRounds': teamBSetScores.length, // Total sets played
                'logo': match?.teamB?.clubId?.logo ?? '',
              },
            };
          }
        } else {
          // Fallback to basic match data if no matchId
          final match = currentLiveMatch.matches?.first;
          if (match != null) {
            final teamAPlayers = match.teamA?.players ?? [];
            final teamBPlayers = match.teamB?.players ?? [];
            
            liveMatchScoreboard.value = {
              'teamA': {
                'players': teamAPlayers.map((player) => {
                  'playerName': player.playerName ?? '',
                  'playerId': player.playerId ?? '',
                }).toList(),
                'currentPoints': '0',
                'setsWon': currentLiveMatch.matchId?.setsWon?.teamA ?? 0,
                'roundScores': [], // Empty for fallback
                'totalRounds': 0,
                'logo': match.teamA?.clubId?.logo ?? '',
              },
              'teamB': {
                'players': teamBPlayers.map((player) => {
                  'playerName': player.playerName ?? '',
                  'playerId': player.playerId ?? '',
                }).toList(),
                'currentPoints': '0',
                'setsWon': currentLiveMatch.matchId?.setsWon?.teamB ?? 0,
                'roundScores': [], // Empty for fallback
                'totalRounds': 0,
                'logo': match.teamB?.clubId?.logo ?? '',
              },
            };
          }
        }
      }
    } catch (e) {
      print('Error fetching live match scoreboard: $e');
    } finally {
      isLoadingScoreboard.value = false;
    }
  }
  
  void _connectWebSocket() {
    try {
      // Prevent multiple connections
      if (_socket != null && isSocketConnected.value) {
        print('🔌 League - Socket already connected');
        return;
      }
      
      final allMatches = upcomingMatches.value?.data;
      final liveMatchData = allMatches?.where((data) => data.matchStatus == 'live').toList();
      if (liveMatchData == null || liveMatchData.isEmpty) return;
      
      final currentIndex = currentLiveMatchIndex.value < liveMatchData.length ? currentLiveMatchIndex.value : 0;
      final currentLiveMatch = liveMatchData[currentIndex];
      final matchId = currentLiveMatch.matchId?.id;
      
      if (matchId == null || matchId.isEmpty) return;
      
      print('🔌 League - Connecting WebSocket for matchId: $matchId');
      
      final userId = storage.read('userId')?.toString() ?? '';
      _socket = IO.io(
        "${AppEndpoints.socketUrl}/score",
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'userId': userId})
            .build(),
      );
      
      _socket?.on('connect', (_) {
        print('✅ League - Socket connected. ID: ${_socket?.id}');
        isSocketConnected.value = true;
        _socket?.emit('joinScoreMatch', matchId);
      });
      
      _socket?.on('disconnect', (reason) {
        log('❌ League - Socket disconnected: $reason');
        isSocketConnected.value = false;
      });
      
      _socket?.on('connect_error', (err) {
        log('⚠️ League - Socket connection failed: $err');
      });
      
      _socket?.on('scoreUpdate', (data) {
        print('📊 League - Score update received');
        print('📊 League - Full scoreUpdate data: ${data.toString().substring(0, data.toString().length > 1000 ? 1000 : data.toString().length)}...');
        if (data is Map<String, dynamic>) {
          final scoreboard = data['scoreboard'];
          print('📋 League - Scoreboard keys: ${scoreboard is Map ? (scoreboard as Map).keys.toList() : 'Not a map'}');
          _updateLiveScoreboard(scoreboard);
        }
      });
      
      _socket?.on('scoreMatchJoined', (data) {
        print('🎯 League - Match joined event received');
        print('🎯 League - Full scoreMatchJoined data: ${data.toString().substring(0, data.toString().length > 1000 ? 1000 : data.toString().length)}...');
        if (data is Map<String, dynamic> && data.containsKey('scoreboard')) {
          final scoreboard = data['scoreboard'];
          print('📋 League - Scoreboard keys: ${scoreboard is Map ? (scoreboard as Map).keys.toList() : 'Not a map'}');
          _updateLiveScoreboard(data['scoreboard']);
        }
      });
      
      _socket?.on('matchFinished', (data) {
        log('🏁 League - Match finished event received');
        fetchUpcomingMatches();
        fetchResultMatches();
      });
      
    } catch (e) {
      log('❌ League - WebSocket error: $e');
    }
  }
  
  void _disconnectWebSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isSocketConnected.value = false;
  }
  
  void _updateLiveScoreboard(dynamic scoreboard) {
    try {
      print('🔄 League - Updating scoreboard with data: $scoreboard');
      if (scoreboard is Map<String, dynamic>) {
        // Extract current points and sets data
        final points = scoreboard['points'] as Map<String, dynamic>? ?? {};
        final setsWon = scoreboard['setsWon'] as Map<String, dynamic>? ?? {};
        final sets = scoreboard['sets'] as List? ?? [];
        
        print('📊 League - Extracted data: points=$points, setsWon=$setsWon, sets=${sets.length} sets');
        
        // Update the upcoming matches data with new scores for ONLY current live match
        final currentMatches = upcomingMatches.value;
        if (currentMatches?.data?.isNotEmpty == true) {
          final liveMatches = currentMatches!.data!.where((data) => data.matchStatus == 'live').toList();
          if (liveMatches.isNotEmpty) {
            final currentIndex = currentLiveMatchIndex.value < liveMatches.length ? currentLiveMatchIndex.value : 0;
            final currentLiveMatch = liveMatches[currentIndex];
            final currentMatchId = currentLiveMatch.matchId?.id;
            
            final updatedData = currentMatches.data!.map((matchData) {
              // Sirf current carousel wale match ko update karo
              if (matchData.matchId?.id == currentMatchId && matchData.matchId?.setsWon != null) {
                final newTeamAScore = setsWon['teamA'] ?? matchData.matchId!.setsWon!.teamA;
                final newTeamBScore = setsWon['teamB'] ?? matchData.matchId!.setsWon!.teamB;
                
                print('📊 League - Updating scores for matchId $currentMatchId: TeamA: ${matchData.matchId!.setsWon!.teamA} -> $newTeamAScore, TeamB: ${matchData.matchId!.setsWon!.teamB} -> $newTeamBScore');
                
                matchData.matchId!.setsWon!.teamA = newTeamAScore;
                matchData.matchId!.setsWon!.teamB = newTeamBScore;
              }
              return matchData;
            }).toList();
            
            // Force update the observable with a new instance to trigger UI rebuild
            final newMatches = GetAllScheduleLiveMatchesModel(
              success: currentMatches.success,
              data: updatedData,
              pagination: currentMatches.pagination,
            );
            
            upcomingMatches.value = newMatches;
            upcomingMatches.refresh();
            
            print('✅ League - Live match updated successfully for matchId: $currentMatchId');
          }
        }
        
        // Update the detailed scoreboard data for the scoreboard widget
        final currentScoreboard = liveMatchScoreboard.value ?? {};
        final updatedScoreboard = Map<String, dynamic>.from(currentScoreboard);
        
        // Extract completed sets' final scores for ScoreBoardRow
        List<String> teamASetScores = [];
        List<String> teamBSetScores = [];
        
        // Process each set with detailed logging
        for (int i = 0; i < sets.length; i++) {
          final set = sets[i];
          if (set is Map<String, dynamic>) {
            print('🔍 League - Set $i structure: ${set.keys.toList()}');
            print('🔍 League - Set $i data: $set');
            
            // Check for finalScore first (this should be the correct format)
            final finalScore = set['finalScore'] as Map<String, dynamic>?;
            final setWinner = set['setWinner'] as String?;
            final setNumber = set['setNumber'];
            
            if (finalScore != null && finalScore.isNotEmpty) {
              final teamAScore = finalScore['teamA']?.toString() ?? '0';
              final teamBScore = finalScore['teamB']?.toString() ?? '0';
              
              teamASetScores.add(teamAScore);
              teamBSetScores.add(teamBScore);
              
              print('🎯 League - Set $setNumber Final Score: TeamA=$teamAScore, TeamB=$teamBScore, Winner=$setWinner');
            }
            // Fallback to direct teamA/teamB scores if finalScore not available
            else {
              final teamAScore = set['teamA'];
              final teamBScore = set['teamB'];
              
              if (teamAScore != null && teamBScore != null) {
                teamASetScores.add(teamAScore.toString());
                teamBSetScores.add(teamBScore.toString());
                
                print('🎯 League - Set Direct Score: TeamA=$teamAScore, TeamB=$teamBScore');
              }
            }
          }
        }
        
        // Current points for ongoing set
        final teamAPoints = points['teamA']?.toString() ?? '0';
        final teamBPoints = points['teamB']?.toString() ?? '0';
        
        print('🎯 League - Current points: TeamA=$teamAPoints, TeamB=$teamBPoints');
        print('🎯 League - Completed sets scores: TeamA=$teamASetScores, TeamB=$teamBSetScores');
        
        // Update scoreboard data
        if (updatedScoreboard.containsKey('teamA')) {
          updatedScoreboard['teamA']['currentPoints'] = teamAPoints;
          updatedScoreboard['teamA']['setsWon'] = setsWon['teamA'] ?? 0;
          updatedScoreboard['teamA']['roundScores'] = teamASetScores; // Use set scores instead of round scores
          updatedScoreboard['teamA']['totalRounds'] = teamASetScores.length;
        }
        
        if (updatedScoreboard.containsKey('teamB')) {
          updatedScoreboard['teamB']['currentPoints'] = teamBPoints;
          updatedScoreboard['teamB']['setsWon'] = setsWon['teamB'] ?? 0;
          updatedScoreboard['teamB']['roundScores'] = teamBSetScores; // Use set scores instead of round scores
          updatedScoreboard['teamB']['totalRounds'] = teamBSetScores.length;
        }
        
        liveMatchScoreboard.value = updatedScoreboard;
        liveMatchScoreboard.refresh(); // Force UI update
        print('✅ League - Detailed scoreboard updated with current points: TeamA=$teamAPoints, TeamB=$teamBPoints and completed sets: ${teamASetScores.length}');
      }
    } catch (e) {
      print('❌ League - Error updating scoreboard: $e');
    }
  }
}