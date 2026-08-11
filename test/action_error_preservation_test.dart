import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:rahhal_flutter/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:rahhal_flutter/features/trip_documents/domain/entities/document_entity.dart';
import 'package:rahhal_flutter/features/trip_documents/domain/repositories/document_repository.dart';
import 'package:rahhal_flutter/features/trip_documents/presentation/cubit/document_cubit.dart';
import 'package:rahhal_flutter/features/trip_documents/presentation/cubit/document_state.dart';

/// Regression test for "a failed add/update/delete/toggle wiped the whole
/// already-loaded list with a full-screen error" — DocumentCubit and
/// FavoritesCubit both used to emit their bare Error state on any action
/// failure, discarding everything already on screen. Mirrors the pattern
/// BudgetCubit/SavedTripsCubit already used correctly (proven in earlier
/// tests this session).
class _MockDocumentRepository extends Mock implements DocumentRepository {}

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

DocumentEntity _doc(String id) => DocumentEntity(
      id: id,
      tripId: 't1',
      docType: 'passport',
      title: 'doc-$id',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('DocumentCubit', () {
    late _MockDocumentRepository repo;
    late DocumentCubit cubit;

    setUp(() {
      repo = _MockDocumentRepository();
      cubit = DocumentCubit(repository: repo);
    });

    test('a failed delete keeps the loaded list, with actionError set',
        () async {
      when(() => repo.getDocuments('t1'))
          .thenAnswer((_) async => Right([_doc('a'), _doc('b')]));
      await cubit.loadDocuments('t1');

      when(() => repo.deleteDocument('a'))
          .thenAnswer((_) async => const Left(DatabaseFailure('locked')));
      await cubit.deleteDocument('t1', 'a');

      final state = cubit.state as DocumentsLoaded;
      expect(state.documents.map((d) => d.id), ['a', 'b'],
          reason: 'nothing was actually deleted, so nothing should vanish '
              'from the list either');
      expect(state.actionError, 'locked');
    });

    test('clearActionError removes the message but keeps the list', () async {
      when(() => repo.getDocuments('t1'))
          .thenAnswer((_) async => Right([_doc('a')]));
      await cubit.loadDocuments('t1');
      when(() => repo.deleteDocument('a'))
          .thenAnswer((_) async => const Left(DatabaseFailure('x')));
      await cubit.deleteDocument('t1', 'a');

      cubit.clearActionError();

      final state = cubit.state as DocumentsLoaded;
      expect(state.actionError, isNull);
      expect(state.documents, hasLength(1));
    });
  });

  group('FavoritesCubit', () {
    late _MockFavoritesRepository repo;
    late FavoritesCubit cubit;

    setUp(() {
      repo = _MockFavoritesRepository();
      cubit = FavoritesCubit(repository: repo);
    });

    test('a failed updateNotes keeps the loaded list, with actionError set',
        () async {
      when(() => repo.getFavorites()).thenAnswer((_) async => const Right([]));
      await cubit.loadFavorites();

      when(() => repo.updateNotes('stop', 's1', 'note'))
          .thenAnswer((_) async => const Left(DatabaseFailure('locked')));
      await cubit.updateNotes('stop', 's1', 'note');

      final state = cubit.state as FavoritesLoaded;
      expect(state.actionError, 'locked');
    });

    test('a failed toggle rolls back via reload rather than blanking the state',
        () async {
      when(() => repo.getFavorites()).thenAnswer((_) async => const Right([]));
      await cubit.loadFavorites();

      when(() => repo.toggleFavorite('stop', 's1',
              tripId: 't1', destinationName: null, notes: null))
          .thenAnswer((_) async => const Left(DatabaseFailure('locked')));
      await cubit.toggleFavorite('stop', 's1', tripId: 't1');

      // loadFavorites() runs right after the failure and is what actually
      // completes the cubit's async chain — by then the state must be a real
      // FavoritesLoaded again (the rollback), never left on FavoritesError.
      expect(cubit.state, isA<FavoritesLoaded>());
    });
  });
}
