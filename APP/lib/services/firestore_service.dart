import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirestoreService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  // Add user if not exists
  Future<void> addUser(User user) async {
    final QuerySnapshot result =
        await users.where('username', isEqualTo: user.username).get();
    final List<DocumentSnapshot> documents = result.docs;

    if (documents.isEmpty) {
      await users.add(user.toMap());
    } else {
      throw Exception('User already exists');
    }
  }

  // Validate user credentials
  Future<bool> validateUser(String username, String password) async {
    final QuerySnapshot result = await users
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<String?> GetUserID(String username, String password) async {
    final QuerySnapshot result = await users
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    // If a valid user is found, return their user ID, otherwise return null
    if (result.docs.isNotEmpty) {
      return result.docs.first.id; // Renvoie l'ID du premier document trouvé
    } else {
      return null;
    }
  }

  // Nouvelle fonction pour obtenir le username à partir de l'ID
  Future<String?> getUsernameById(String userId) async {
    try {
      // Chercher l'utilisateur par ID
      final DocumentSnapshot userDoc = await users.doc(userId).get();

      // Vérifier si le document existe
      if (userDoc.exists) {
        // Retourner le username à partir du document
        return userDoc[
            'username']; // Assurez-vous que le champ 'username' existe
      } else {
        return null; // Si l'utilisateur n'existe pas
      }
    } catch (e) {
      print("Erreur lors de la récupération du username: $e");
      return null;
    }
  }

  Stream<List<QueryDocumentSnapshot>> getAllUsers() {
    return users.snapshots().map((snapshot) => snapshot.docs);
  }

  Stream<QuerySnapshot> getUserByUsername(String username) {
    return users.where('username', isEqualTo: username).snapshots();
  }
}
