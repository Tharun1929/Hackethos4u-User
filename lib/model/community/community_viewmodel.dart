import 'package:flutter/foundation.dart';
import '../../api/community_api.dart';

class CommunityViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _channels = [];
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _participants = [];
  Map<String, dynamic>? _currentChannel;
  bool _isLoading = false;
  bool _isConnected = true;
  int _onlineMembers = 0;
  int _unreadCount = 0;
  String _errorMessage = '';

  // Getters
  List<Map<String, dynamic>> get channels => _channels;
  List<Map<String, dynamic>> get messages => _messages;
  List<Map<String, dynamic>> get participants => _participants;
  Map<String, dynamic>? get currentChannel => _currentChannel;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  int get onlineMembers => _onlineMembers;
  int get unreadCount => _unreadCount;
  String get errorMessage => _errorMessage;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Set connection status
  void setConnectionStatus(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  // Set current channel
  void setCurrentChannel(Map<String, dynamic> channel) {
    _currentChannel = channel;
    notifyListeners();
  }

  // Load all channels
  Future<void> loadChannels() async {
    try {
      _setLoading(true);
      _setError('');

      final channels = await CommunityAPI.getChannels();
      _channels = channels;

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load channels: $e');
    }
  }

  // Load joined channels
  Future<void> loadJoinedChannels() async {
    try {
      _setLoading(true);
      _setError('');

      final channels = await CommunityAPI.getJoinedChannels();
      _channels = channels;

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load joined channels: $e');
    }
  }

  // Load messages for a channel
  Future<void> loadMessages(String channelId, {int page = 1}) async {
    try {
      _setLoading(true);
      _setError('');

      final messages = await CommunityAPI.getMessages(channelId, page: page);

      if (page == 1) {
        _messages = messages;
      } else {
        _messages.insertAll(0, messages);
      }

      // Mark messages as read
      await markMessagesAsRead(channelId);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load messages: $e');
    }
  }

  // Send a message
  Future<bool> sendMessage(
    String channelId,
    String message, {
    String? imagePath,
    String? filePath,
    String? fileName,
  }) async {
    try {
      _setError('');

      final result = await CommunityAPI.sendMessage(
        channelId,
        message,
        imagePath: imagePath,
        filePath: filePath,
        fileName: fileName,
      );

      // Add the new message to the list
      _messages.add(result);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  // Load participants for a channel
  Future<void> loadParticipants(String channelId) async {
    try {
      _setLoading(true);
      _setError('');

      final participants = await CommunityAPI.getParticipants(channelId);
      _participants = participants;

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load participants: $e');
    }
  }

  // Join a channel
  Future<bool> joinChannel(String channelId) async {
    try {
      _setError('');

      await CommunityAPI.joinChannel(channelId);

      // Reload channels to reflect the change
      await loadJoinedChannels();

      return true;
    } catch (e) {
      _setError('Failed to join channel: $e');
      return false;
    }
  }

  // Leave a channel
  Future<bool> leaveChannel(String channelId) async {
    try {
      _setError('');

      await CommunityAPI.leaveChannel(channelId);

      // Reload channels to reflect the change
      await loadJoinedChannels();

      return true;
    } catch (e) {
      _setError('Failed to leave channel: $e');
      return false;
    }
  }

  // Create a new channel
  Future<bool> createChannel({
    required String name,
    required String description,
    bool isPrivate = false,
    String? courseId,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      await CommunityAPI.createChannel(
        name: name,
        description: description,
        isPrivate: isPrivate,
        courseId: courseId,
      );

      // Reload channels to include the new one
      await loadJoinedChannels();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to create channel: $e');
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String channelId) async {
    try {
      await CommunityAPI.markMessagesAsRead(channelId);

      // Update unread count
      await loadUnreadCount();
    } catch (e) {
      // Don't show error for this operation as it's not critical
      // Failed to mark messages as read: $e
    }
  }

  // Load unread message count
  Future<void> loadUnreadCount() async {
    try {
      final result = await CommunityAPI.getUnreadCount();
      _unreadCount = result['count'] ?? 0;
      notifyListeners();
    } catch (e) {
      // Failed to load unread count: $e
    }
  }

  // Search messages
  Future<List<Map<String, dynamic>>> searchMessages(
    String channelId,
    String query, {
    int page = 1,
  }) async {
    try {
      _setError('');

      final results = await CommunityAPI.searchMessages(
        channelId,
        query,
        page: page,
      );

      return results;
    } catch (e) {
      _setError('Failed to search messages: $e');
      return [];
    }
  }

  // Report a message
  Future<bool> reportMessage(String messageId, String reason) async {
    try {
      _setError('');

      await CommunityAPI.reportMessage(messageId, reason);

      return true;
    } catch (e) {
      _setError('Failed to report message: $e');
      return false;
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      _setError('');

      await CommunityAPI.deleteMessage(messageId);

      // Remove the message from the local list
      _messages.removeWhere((message) => message['id'] == messageId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete message: $e');
      return false;
    }
  }

  // Edit a message
  Future<bool> editMessage(String messageId, String newText) async {
    try {
      _setError('');

      final result = await CommunityAPI.editMessage(messageId, newText);

      // Update the message in the local list
      final index =
          _messages.indexWhere((message) => message['id'] == messageId);
      if (index != -1) {
        _messages[index] = result;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to edit message: $e');
      return false;
    }
  }

  // Load channel statistics
  Future<Map<String, dynamic>?> loadChannelStats(String channelId) async {
    try {
      _setError('');

      final stats = await CommunityAPI.getChannelStats(channelId);
      return stats;
    } catch (e) {
      _setError('Failed to load channel stats: $e');
      return null;
    }
  }

  // Load online users count
  Future<void> loadOnlineUsersCount(String channelId) async {
    try {
      final result = await CommunityAPI.getOnlineUsersCount(channelId);
      _onlineMembers = result['count'] ?? 0;
      notifyListeners();
    } catch (e) {
      // Failed to load online users count: $e
    }
  }

  // Add a new message (for real-time updates)
  void addMessage(Map<String, dynamic> message) {
    _messages.add(message);
    notifyListeners();
  }

  // Update a message (for real-time updates)
  void updateMessage(String messageId, Map<String, dynamic> updatedMessage) {
    final index = _messages.indexWhere((message) => message['id'] == messageId);
    if (index != -1) {
      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  // Remove a message (for real-time updates)
  void removeMessage(String messageId) {
    _messages.removeWhere((message) => message['id'] == messageId);
    notifyListeners();
  }

  // Clear messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _channels.clear();
    _messages.clear();
    _participants.clear();
    _currentChannel = null;
    _onlineMembers = 0;
    _unreadCount = 0;
    _errorMessage = '';
    notifyListeners();
  }

  // Check if user is in a channel
  bool isUserInChannel(String channelId) {
    return _channels.any((channel) => channel['id'] == channelId);
  }

  // Get channel by ID
  Map<String, dynamic>? getChannelById(String channelId) {
    try {
      return _channels.firstWhere((channel) => channel['id'] == channelId);
    } catch (e) {
      return null;
    }
  }

  // Get message by ID
  Map<String, dynamic>? getMessageById(String messageId) {
    try {
      return _messages.firstWhere((message) => message['id'] == messageId);
    } catch (e) {
      return null;
    }
  }

  // Get participant by ID
  Map<String, dynamic>? getParticipantById(String participantId) {
    try {
      return _participants
          .firstWhere((participant) => participant['id'] == participantId);
    } catch (e) {
      return null;
    }
  }

  // Check if message is from current user
  bool isMessageFromCurrentUser(Map<String, dynamic> message) {
    // This should be implemented based on your user authentication system
    // For now, we'll assume the current user ID is stored somewhere
    final currentUserId = 'current_user_id'; // Replace with actual user ID
    return message['user_id'] == currentUserId;
  }

  // Get formatted timestamp
  String getFormattedTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Get message status text
  String getMessageStatus(Map<String, dynamic> message) {
    if (message['is_edited'] == true) {
      return 'Edited';
    } else if (message['is_deleted'] == true) {
      return 'Deleted';
    } else {
      return '';
    }
  }

  // Check if channel has unread messages
  bool hasUnreadMessages(String channelId) {
    // This should be implemented based on your unread message tracking system
    // For now, we'll return false
    return false;
  }

  // Get unread count for a specific channel
  int getUnreadCountForChannel(String channelId) {
    // This should be implemented based on your unread message tracking system
    // For now, we'll return 0
    return 0;
  }
}
