// lib/application/blockchain_bloc.dart
// ─────────────────────────────────────────────────────────────────────────────
// BLoC for blockchain operations
// ─────────────────────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:edi_translator/data/blockchain_api.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

abstract class BlockchainEvent extends Equatable {
  const BlockchainEvent();
  @override
  List<Object?> get props => [];
}

class BCLoadChain extends BlockchainEvent {
  const BCLoadChain();
}

class BCAddBlock extends BlockchainEvent {
  const BCAddBlock({
    required this.studentId,
    required this.course,
    required this.credits,
    required this.creator,
  });
  final String studentId;
  final String course;
  final int credits;
  final String creator;
  @override
  List<Object?> get props => [studentId, course, credits, creator];
}

class BCSearchStudent extends BlockchainEvent {
  const BCSearchStudent(this.studentId);
  final String studentId;
  @override
  List<Object?> get props => [studentId];
}

class BCLoadNodes extends BlockchainEvent {
  const BCLoadNodes();
}

class BCAddNode extends BlockchainEvent {
  const BCAddNode(this.node);
  final String node;
  @override
  List<Object?> get props => [node];
}

class BCCheckStatus extends BlockchainEvent {
  const BCCheckStatus();
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

abstract class BlockchainState extends Equatable {
  const BlockchainState();
  @override
  List<Object?> get props => [];
}

class BCInitial extends BlockchainState {
  const BCInitial();
}

class BCLoading extends BlockchainState {
  const BCLoading();
}

class BCChainLoaded extends BlockchainState {
  const BCChainLoaded(this.chain);
  final List<Map<String, dynamic>> chain;
  @override
  List<Object?> get props => [chain];
}

class BCBlockAdded extends BlockchainState {
  const BCBlockAdded({required this.message, required this.block});
  final String message;
  final Map<String, dynamic>? block;
  @override
  List<Object?> get props => [message, block];
}

class BCSearchResult extends BlockchainState {
  const BCSearchResult({
    required this.studentId,
    required this.records,
  });
  final String studentId;
  final List<Map<String, dynamic>> records;
  @override
  List<Object?> get props => [studentId, records];
}

class BCNodesLoaded extends BlockchainState {
  const BCNodesLoaded(this.nodes);
  final List<String> nodes;
  @override
  List<Object?> get props => [nodes];
}

class BCNodeAdded extends BlockchainState {
  const BCNodeAdded(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class BCServerStatus extends BlockchainState {
  const BCServerStatus(this.isOnline);
  final bool isOnline;
  @override
  List<Object?> get props => [isOnline];
}

class BCError extends BlockchainState {
  const BCError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLoC
// ─────────────────────────────────────────────────────────────────────────────

class BlockchainBloc extends Bloc<BlockchainEvent, BlockchainState> {
  BlockchainBloc() : super(const BCInitial()) {
    on<BCLoadChain>(_onLoadChain);
    on<BCAddBlock>(_onAddBlock);
    on<BCSearchStudent>(_onSearchStudent);
    on<BCLoadNodes>(_onLoadNodes);
    on<BCAddNode>(_onAddNode);
    on<BCCheckStatus>(_onCheckStatus);
  }

  Future<void> _onLoadChain(BCLoadChain e, Emitter<BlockchainState> emit) async {
    emit(const BCLoading());
    try {
      final chain = await BlockchainApi.getChain();
      emit(BCChainLoaded(chain));
    } catch (ex) {
      emit(BCError(_msg(ex)));
    }
  }

  Future<void> _onAddBlock(BCAddBlock e, Emitter<BlockchainState> emit) async {
    emit(const BCLoading());
    try {
      final result = await BlockchainApi.addBlock(
        studentId: e.studentId,
        course: e.course,
        credits: e.credits,
        creator: e.creator,
      );
      emit(BCBlockAdded(
        message: result['message'] ?? 'Block processed.',
        block: result['block'] != null
            ? Map<String, dynamic>.from(result['block'])
            : null,
      ));
    } catch (ex) {
      emit(BCError(_msg(ex)));
    }
  }

  Future<void> _onSearchStudent(
      BCSearchStudent e, Emitter<BlockchainState> emit) async {
    emit(const BCLoading());
    try {
      final records = await BlockchainApi.searchStudent(e.studentId);
      emit(BCSearchResult(studentId: e.studentId, records: records));
    } catch (ex) {
      emit(BCError(_msg(ex)));
    }
  }

  Future<void> _onLoadNodes(
      BCLoadNodes e, Emitter<BlockchainState> emit) async {
    emit(const BCLoading());
    try {
      final nodes = await BlockchainApi.getNodes();
      emit(BCNodesLoaded(nodes));
    } catch (ex) {
      emit(BCError(_msg(ex)));
    }
  }

  Future<void> _onAddNode(BCAddNode e, Emitter<BlockchainState> emit) async {
    emit(const BCLoading());
    try {
      final result = await BlockchainApi.addNode(e.node);
      emit(BCNodeAdded(result['message'] ?? 'Node processed.'));
    } catch (ex) {
      emit(BCError(_msg(ex)));
    }
  }

  Future<void> _onCheckStatus(
      BCCheckStatus e, Emitter<BlockchainState> emit) async {
    final online = await BlockchainApi.isReachable();
    emit(BCServerStatus(online));
  }

  String _msg(Object ex) {
    if (ex is ApiException) return ex.message;
    if (ex.toString().contains('SocketException') ||
        ex.toString().contains('Connection refused') ||
        ex.toString().contains('TimeoutException')) {
      return 'Cannot reach server at 10.0.2.2:5000.\nMake sure Flask is running on your PC.';
    }
    return ex.toString();
  }
}
