import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_card.dart';
import '../services/api_service.dart';
import '../models/post.dart';
import '../models/sender_post.dart';
import '../models/courier_post.dart';
import '../widgets/tab_bar_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/post_details_popup.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  Future<List<Post>>? _myPosts;
  int _selectedTabIndex = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserIdAndFetchPosts();
  }

  Future<void> _loadCurrentUserIdAndFetchPosts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    if (_currentUserId == null) return;
    setState(() {
      _myPosts = Future(() async {
        final results = await Future.wait([
          _apiService.fetchMySenderPosts(),
          // CourierPost fetching might be adjusted if your main flow is on SenderPost
        ]);
        final List<SenderPost> senderPosts = results[0] as List<SenderPost>;
        // final List<CourierPost> courierPosts = results[1] as List<CourierPost>; // Assuming less focus on separate CourierPost lifecycle for now

        final List<Post> combinedPosts = [];
        combinedPosts.addAll(senderPosts.map((post) => Post(
              type: 'sender', // Or determine based on context if a post can be both
              from: post.from,
              to: post.to,
              date: post.sendTime,
              userLocation: '${post.user.name} ${post.user.surname}',
              userId: post.user.id,
              postId: post.id,
              price: post.parcelPrice,
              description: post.description,
              phoneNumber: post.user.phoneNumber,
              status: post.status,
              id: post.id,
              courierId: post.courierId, // Make sure courierId is included
              senderRatedCourier: post.senderRatedCourier,
              courierRatedSender: post.courierRatedSender,
            )));

        // If you have a separate flow for CourierPosts that also appear in history:
        // combinedPosts.addAll(courierPosts.map((post) => Post(...)));
        
        return combinedPosts;
      });
    });
  }

  void _showRatingDialog(BuildContext context, String postId, String targetUserId, bool isSenderPost) {
    int? _rating;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('rate_user'.tr()),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('select_rating'.tr()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          _rating != null && _rating! > index ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('submit'.tr()),
              onPressed: () async {
                if (_rating != null) {
                  try {
                    if (isSenderPost) { // Assuming rating logic is primarily for SenderPosts
                      await _apiService.rateSenderPost(postId, targetUserId, _rating!);
                    } else {
                      // await _apiService.rateCourierPost(postId, targetUserId, _rating!);
                    }
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('rating_submitted'.tr())),
                    );
                    _fetchMyPosts(); // Refresh posts to show updated rating status
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Montserrat',
          fontFamilyFallback: ['Roboto'],
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF7FF),
        appBar: AppBar(
          title: Text('history'.tr(), style: const TextStyle(fontFamily: 'Montserrat')),
          centerTitle: true,
          backgroundColor: const Color(0xFFFEF7FF),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            TabBarWidget(
              firstTab: 'active'.tr(),
              secondTab: 'completed'.tr(),
              onTabChanged: (index) => setState(() => _selectedTabIndex = index),
            ),
            Expanded(
              child: FutureBuilder<List<Post>>(
                future: _myPosts,
                builder: (context, snapshot) {
                  if (_currentUserId == null || snapshot.connectionState == ConnectionState.waiting && _myPosts == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontFamily: 'Montserrat')));
                  }
                  final posts = snapshot.data ?? [];
                  final filteredPosts = posts.where((post) {
                    bool isActiveTab = _selectedTabIndex == 0 && (post.status == 'active' || post.status == 'pending_acceptance' || post.status == 'pending_sender_confirmation');
                    bool isCompletedTab = _selectedTabIndex == 1 && post.status == 'completed';
                    return isActiveTab || isCompletedTab;
                  }).toList();

                  if (filteredPosts.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedTabIndex == 0 ? 'no_active_posts'.tr() : 'no_completed_posts'.tr(),
                        style: const TextStyle(fontFamily: 'Montserrat'),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      bool isCurrentUserCourier = post.courierId == _currentUserId;
                      bool isCurrentUserSender = post.userId == _currentUserId;

                      List<Widget> actionButtons = [];

                      // Courier: Mark as Delivered
                      if (post.status == 'active' && isCurrentUserCourier) {
                        actionButtons.add(
                          ElevatedButton(
                            child: Text('mark_as_delivered'.tr()),
                            onPressed: () async {
                              try {
                                await _apiService.markAsDeliveredByCourier(post.postId);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('delivery_marked_completed'.tr())));
                                _fetchMyPosts(); // Refresh
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
                          )
                        );
                      }

                      // Sender: Confirm Completion
                      if (post.status == 'pending_sender_confirmation' && isCurrentUserSender) {
                         actionButtons.add(
                          ElevatedButton(
                            child: Text('confirm_completion'.tr()),
                            onPressed: () async {
                              try {
                                await _apiService.confirmCompletionBySender(post.postId);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('delivery_confirmed'.tr())));
                                _fetchMyPosts(); // Refresh
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
                          )
                        );
                      }
                      
                      // Rating buttons for completed posts
                      if (post.status == 'completed') {
                        // Sender rates Courier
                        if (isCurrentUserSender && post.courierId != null && !(post.senderRatedCourier ?? false)) {
                          actionButtons.add(
                            ElevatedButton(
                              child: Text('rate_courier'.tr()),
                              onPressed: () => _showRatingDialog(context, post.postId, post.courierId!, true),
                            )
                          );
                        }
                        // Courier rates Sender
                        if (isCurrentUserCourier && !(post.courierRatedSender ?? false)) {
                           actionButtons.add(
                            ElevatedButton(
                              child: Text('rate_sender'.tr()),
                              onPressed: () => _showRatingDialog(context, post.postId, post.userId, true), // Assuming SenderPost rating
                            )
                          );
                        }
                      }


                      return PostCard(
                        from: post.from.tr(),
                        to: post.to.tr(),
                        date: post.date,
                        userLocation: post.userLocation, // This is the post creator's name
                        price: post.price,
                        status: post.status, // Pass status to PostCard
                        onMorePressed: () => PostDetailsPopup.show(context, post),
                        leading: Icon(
                          post.type == 'sender' ? Icons.send : Icons.local_shipping,
                          color: const Color(0xFF201731),
                        ),
                        actionButtons: actionButtons, // Pass buttons to PostCard
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 