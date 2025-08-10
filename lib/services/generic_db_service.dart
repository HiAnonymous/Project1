// lib/services/generic_db_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/type_defs.dart';

class GenericDBService<T> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionName;
  final T Function(Json) fromJson;

  GenericDBService(this.collectionName, this.fromJson);

  CollectionReference<T> get collection =>
      _db.collection(collectionName).withConverter<T>(
            fromFirestore: (snapshot, _) => fromJson(snapshot.data()!),
            toFirestore: (value, _) => (value as dynamic).toJson(),
          );

  Future<void> create(String id, T data) async {
    await collection.doc(id).set(data);
  }

  Future<T?> get(String id) async {
    final snapshot = await collection.doc(id).get();
    return snapshot.data();
  }

  Future<List<T>> getAll() async {
    final snapshot = await collection.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<T>> getAllStream() {
    return collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> update(String id, T data) async {
    await collection.doc(id).update((data as dynamic).toJson());
  }

  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }
} 