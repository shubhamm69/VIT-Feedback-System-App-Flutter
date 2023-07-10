import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smartcityfeedbacksystem/models/feedback_model.dart';
import 'package:smartcityfeedbacksystem/models/user_model.dart';

class UserProvider with ChangeNotifier {
  late UserModel _user;

  UserModel get user => _user;

  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> submitFeedback(BuildContext context, String title, String problem, List<String> selectedImages) async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      // Create a new feedback document in Firestore
      final feedbacksRef = FirebaseFirestore.instance.collection('feedbacks');
      final feedbackDoc = feedbacksRef.doc();

      // Upload images to Firebase Storage and get their download URLs
      List<String> uploadedImageUrls = [];
      for (String imagePath in selectedImages) {
        final Reference storageRef = FirebaseStorage.instance.ref().child('feedback_images/${feedbackDoc.id}/${DateTime.now().millisecondsSinceEpoch.toString()}');
        final UploadTask uploadTask = storageRef.putFile(File(imagePath));
        final TaskSnapshot uploadSnapshot = await uploadTask;
        final String imageUrl = await uploadSnapshot.ref.getDownloadURL();
        uploadedImageUrls.add(imageUrl);
      }

      // Create the feedback data
      final feedbackData = {
        'title': title,
        'problem': problem,
        'images': uploadedImageUrls,
        // Add any additional data you want to store
      };

      // Set the feedback data in the Firestore document
      await feedbackDoc.set(feedbackData);

      // Update the user's feedbacks list
      final updatedFeedbacks = List<FeedbackModel>.from(_user.feedbacks);
      updatedFeedbacks.add(
        FeedbackModel(
          id: feedbackDoc.id,
          userId: _user.uid,
          title: title,
          problemFaced: problem,
          imagePath: uploadedImageUrls.isNotEmpty ? uploadedImageUrls[0] : '',
          upvotes: 0,
          downvotes: 0,
          comments: [],
        ),
      );

      // Create the updated user model
      final updatedUser = UserModel(
        name: _user.name,
        email: _user.email,
        bio: _user.bio,
        regno: _user.regno,
        profilePic: _user.profilePic,
        createdAt: _user.createdAt,
        phoneNumber: _user.phoneNumber,
        uid: _user.uid,
        feedbacks: updatedFeedbacks,
      );

      // Update the user in the provider
      _user = updatedUser;

      notifyListeners();

      // Show success notification
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Feedback posted successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      // Show error notification
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to submit feedback. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
