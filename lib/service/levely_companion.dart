import 'package:app/model/levely_models.dart';
import 'package:app/service/levely_engine.dart';
import 'package:app/service/levely_gamification.dart';
import 'package:app/service/levely_llm_config.dart';
import 'package:app/service/levely_llm_client.dart';
import 'package:app/service/levely_rag.dart';
import 'package:app/service/levely_runtime_config.dart';
import 'package:flutter/foundation.dart';

class LevelyCompanionObservation {
  final LevelyProgress before;
  final LevelyProgress after;
  final LevelyLearningEvent event;
  final int? pointsDelta;
  final List<LevelyBadge> newlyUnlocked;

  const LevelyCompanionObservation({
    required this.before,
    required this.after,
    required this.event,
    this.pointsDelta,
    this.newlyUnlocked = const [],
  });
}

class LevelyCompanionAutoFeedback {
  final LevelyProgress progress;
  final LevelyLearningEvent event;
  final int? pointsDelta;
  final List<LevelyBadge> newlyUnlocked;
  final String feedback;

  const LevelyCompanionAutoFeedback({
    required this.progress,
    required this.event,
    this.pointsDelta,
    this.newlyUnlocked = const [],
    required this.feedback,
  });
}

class LevelyCompanionObserver {
  static const int _maxHistory = 30;
  static const int _maxTrend = 12;

  LevelyCompanionObservation observeQuiz({
    required LevelyProgress progress,
    required QuizQuestion question,
    required int selectedIndex,
    required DateTime now,
  }) {
    final before = progress;
    final result = LevelyGamification.applyQuizResult(
      progress: progress,
      question: question,
      isCorrect: selectedIndex == question.correctIndex,
      now: now,
    );

    final event = LevelyLearningEvent(
      type: LevelyLearningEventType.quiz,
      topic: question.topic,
      correct: selectedIndex == question.correctIndex ? 1 : 0,
      attempted: 1,
      at: now,
    );

    final trendValue = result.progress.topicOrDefault(question.topic).accuracy * 100;
    final updated = _withHistoryAndTrend(result.progress, event, trendValue: trendValue, now: now);

    return LevelyCompanionObservation(
      before: before,
      after: updated,
      event: event,
      pointsDelta: result.pointsDelta,
      newlyUnlocked: result.newlyUnlocked,
    );
  }

  LevelyCompanionObservation observeAssessment({
    required LevelyProgress progress,
    required int correct,
    required int attempted,
    required int score,
    required DateTime now,
    String? topic,
    String? referenceId,
  }) {
    final before = progress;
    final base = _updateDailyStreak(progress, now);
    final event = LevelyLearningEvent(
      type: LevelyLearningEventType.assessment,
      topic: topic,
      correct: correct,
      attempted: attempted,
      score: score,
      referenceId: referenceId,
      at: now,
    );

    if (_alreadyObserved(base, LevelyLearningEventType.assessment, referenceId)) {
      return LevelyCompanionObservation(before: before, after: base, event: event);
    }

    final trendValue = score > 0 ? score.toDouble() : (attempted == 0 ? 0.0 : (correct / attempted) * 100);
    final updated = _withHistoryAndTrend(base, event, trendValue: trendValue, now: now);
    return LevelyCompanionObservation(before: before, after: updated, event: event);
  }

  LevelyCompanionObservation observeAssignment({
    required LevelyProgress progress,
    required DateTime now,
    int? score,
    String? topic,
    String? referenceId,
  }) {
    final before = progress;
    final base = _updateDailyStreak(progress, now);
    final event = LevelyLearningEvent(
      type: LevelyLearningEventType.assignment,
      topic: topic,
      score: score,
      referenceId: referenceId,
      at: now,
    );

    if (_alreadyObserved(base, LevelyLearningEventType.assignment, referenceId)) {
      return LevelyCompanionObservation(before: before, after: base, event: event);
    }

    final trendValue = (score != null && score > 0) ? score.toDouble() : null;
    final updated = _withHistoryAndTrend(base, event, trendValue: trendValue, now: now);
    return LevelyCompanionObservation(before: before, after: updated, event: event);
  }

  bool _alreadyObserved(LevelyProgress progress, LevelyLearningEventType type, String? referenceId) {
    if (referenceId == null || referenceId.trim().isEmpty) return false;
    return progress.history.any((e) => e.type == type && e.referenceId == referenceId);
  }

  LevelyProgress _withHistoryAndTrend(
    LevelyProgress progress,
    LevelyLearningEvent event, {
    required DateTime now,
    double? trendValue,
  }) {
    final history = List<LevelyLearningEvent>.from(progress.history)..add(event);
    final trimmedHistory = history.length <= _maxHistory ? history : history.sublist(history.length - _maxHistory);

    final trend = List<LevelyTrendPoint>.from(progress.trend);
    if (trendValue != null) {
      trend.add(LevelyTrendPoint(type: event.type, value: trendValue, at: now));
    }
    final trimmedTrend = trend.length <= _maxTrend ? trend : trend.sublist(trend.length - _maxTrend);

    return progress.copyWith(history: trimmedHistory, trend: trimmedTrend);
  }

  LevelyProgress _updateDailyStreak(LevelyProgress progress, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final last = progress.lastActiveDate == null
        ? null
        : DateTime(
            progress.lastActiveDate!.year,
            progress.lastActiveDate!.month,
            progress.lastActiveDate!.day,
          );

    if (last == null) {
      return progress.copyWith(dailyStreak: 1, lastActiveDate: today);
    }

    final diffDays = today.difference(last).inDays;
    if (diffDays == 0) {
      return progress.copyWith(lastActiveDate: today);
    }
    if (diffDays == 1) {
      return progress.copyWith(dailyStreak: progress.dailyStreak + 1, lastActiveDate: today);
    }
    return progress.copyWith(dailyStreak: 1, lastActiveDate: today);
  }
}

class LevelyCompanionFeedback {
  String? guardrails({
    required String prompt,
    required LevelyProgress progress,
    String? chapterName,
    String? materialContent,
  }) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return "Tulis pertanyaan singkat tentang bab ini.";
    }

    final lower = trimmed.toLowerCase();
    final hasScope = (chapterName != null && chapterName.trim().isNotEmpty) ||
        (materialContent != null && materialContent.trim().isNotEmpty);
    if (!hasScope) {
      return "Aku hanya bisa jawab saat kamu berada di bab/topik tertentu. Buka babnya lalu tanya di situ.";
    }

    if (_isPerformanceRequest(lower)) {
      if (!_hasSubmission(progress)) {
        return "Feedback performa hanya tersedia setelah kamu submit kuis/assessment/assignment. Selesaikan dulu, lalu aku bantu ringkas hasilnya.";
      }
      if (!_mentionsSubmissionType(lower)) {
        return "Aku bisa bahas hasil submission kamu. Mau bahas hasil kuis, assessment, atau assignment yang mana?";
      }
    }

    final promptTokens = _tokenize(trimmed);
    final chapterTokens = _tokenize(chapterName ?? '');
    final hasChapterName = chapterName != null &&
        chapterName.trim().isNotEmpty &&
        lower.contains(chapterName.trim().toLowerCase());
    final hasContextHint = _hasContextHint(lower);
    final matchesChapter = promptTokens.any(chapterTokens.contains);
    final matchesMaterial = _matchesMaterial(promptTokens, materialContent);

    if (!hasChapterName && !hasContextHint && !matchesChapter && !matchesMaterial) {
      return _outOfScopeMessage(chapterName);
    }
    return null;
  }

  String quizFeedback({
    required LevelyCompanionObservation observation,
    required QuizQuestion question,
    required int selectedIndex,
    required int pointsDelta,
  }) {
    final correct = selectedIndex == question.correctIndex;
    final afterTopic = observation.after.topicOrDefault(question.topic);
    final accuracy = (afterTopic.accuracy * 100).round();
    final trendNote = _trendDeltaNote(
      before: observation.before,
      type: LevelyLearningEventType.quiz,
      currentValue: accuracy.toDouble(),
    );

    final summary = correct ? "Benar" : "Belum tepat";
    final performance = "$summary, akurasi topik ${question.topic} sekarang $accuracy%${trendNote.isEmpty ? '' : ', $trendNote'}.";
    final weakness = _weakPointForTopic(afterTopic);
    final nextStep = _nextStepForTopic(afterTopic);

    return "$performance $weakness${_nextStepSentence(nextStep)}";
  }

  String assessmentFeedback({
    required LevelyCompanionObservation observation,
    required int correct,
    required int attempted,
    required int score,
    String? chapterName,
  }) {
    final label = chapterName == null || chapterName.trim().isEmpty ? "" : " di bab ${chapterName.trim()}";
    final trendNote = _trendDeltaNote(
      before: observation.before,
      type: LevelyLearningEventType.assessment,
      currentValue: score.toDouble(),
    );
    final summary = "Assessment selesai$label. Benar $correct/$attempted, skor $score/100${trendNote.isEmpty ? '' : ', $trendNote'}.";
    final weakness = _weakPointForScore(score, chapterName);
    final nextStep = _nextStepForScore(score, chapterName);
    return "$summary $weakness${_nextStepSentence(nextStep)}";
  }

  String assignmentFeedback({
    required LevelyCompanionObservation observation,
    required int? score,
    String? chapterName,
  }) {
    final label = chapterName == null || chapterName.trim().isEmpty ? "" : " di bab ${chapterName.trim()}";
    if (score == null || score == 0) {
      return "Tugas terkirim$label. Kelemahan belum bisa dinilai karena nilai belum tersedia. Langkah berikutnya: cek rubrik dan tunggu penilaian.";
    }
    final trendNote = _trendDeltaNote(
      before: observation.before,
      type: LevelyLearningEventType.assignment,
      currentValue: score.toDouble(),
    );
    final summary = "Tugas dinilai$label dengan skor $score/100${trendNote.isEmpty ? '' : ', $trendNote'}.";
    final weakness = _weakPointForScore(score, chapterName);
    final nextStep = _nextStepForScore(score, chapterName);
    return "$summary $weakness${_nextStepSentence(nextStep)}";
  }

  String quickAskFallback({
    required String prompt,
    required LevelyProgress progress,
    String? chapterName,
  }) {
    final p = prompt.toLowerCase();
    if (_isPerformanceRequest(p)) {
      if (!_hasSubmission(progress)) {
        return "Feedback performa hanya tersedia setelah kamu submit kuis/assessment/assignment. Selesaikan dulu, lalu aku bantu ringkas hasilnya.";
      }
      if (!_mentionsSubmissionType(p)) {
        return "Aku bisa bahas hasil submission kamu. Mau bahas hasil kuis, assessment, atau assignment yang mana?";
      }
      return "Sebutkan bagian hasil submission yang ingin kamu bahas.";
    }
    if (p.contains('ringkas') || p.contains('summary')) {
      return "Sebutkan bagian${_chapterSuffix(chapterName)} yang ingin diringkas.";
    }
    if (p.contains('contoh') || p.contains('example')) {
      return "Sebutkan topik${_chapterSuffix(chapterName)} yang ingin contoh singkatnya.";
    }
    if (p.contains('quiz') || p.contains('kuis') || p.contains('latihan')) {
      return "Aku bisa buat 3 soal latihan${_chapterSuffix(chapterName)}. Pilih topik yang kamu mau.";
    }

    return "Tanyakan bagian spesifik${_chapterSuffix(chapterName)} yang masih membingungkan.";
  }

  String _chapterSuffix(String? chapterName) {
    if (chapterName == null || chapterName.trim().isEmpty) return "";
    return " di bab ${chapterName.trim()}";
  }

  String _trendDeltaNote({
    required LevelyProgress before,
    required LevelyLearningEventType type,
    required double currentValue,
  }) {
    final prev = _lastTrend(before, type);
    if (prev == null) return '';
    final diff = currentValue - prev.value;
    if (diff.abs() < 1.0) {
      return "stabil dibanding sebelumnya";
    }
    final direction = diff > 0 ? "naik" : "turun";
    return "$direction sekitar ${diff.abs().round()} poin dari sebelumnya";
  }

  LevelyTrendPoint? _lastTrend(LevelyProgress progress, LevelyLearningEventType type) {
    for (var i = progress.trend.length - 1; i >= 0; i--) {
      final point = progress.trend[i];
      if (point.type == type) return point;
    }
    return null;
  }

  String _weakPointForTopic(TopicProgress topic) {
    final accuracy = topic.accuracy;
    if (topic.attempted < 2) {
      return "Bagian lemah: belum terlihat jelas, butuh lebih banyak latihan di topik ${topic.topic}.";
    }
    if (accuracy < 0.6) {
      return "Bagian lemah: akurasi topik ${topic.topic} masih rendah.";
    }
    if (accuracy < 0.8) {
      return "Bagian lemah: konsistensi di topik ${topic.topic} masih naik-turun.";
    }
    return "Bagian lemah: detail kecil di topik ${topic.topic} masih bisa ditajamkan.";
  }

  String _weakPointForScore(int score, String? chapterName) {
    final label = chapterName == null || chapterName.trim().isEmpty ? "materi ini" : "bab ${chapterName.trim()}";
    if (score >= 85) {
      return "Bagian lemah: belum terlihat besar, tapi tetap teliti di $label.";
    }
    if (score >= 60) {
      return "Bagian lemah: beberapa bagian di $label masih belum konsisten.";
    }
    return "Bagian lemah: konsep inti di $label masih lemah.";
  }

  String _nextStepForTopic(TopicProgress topic) {
    final accuracy = topic.accuracy;
    if (accuracy < 0.6) {
      return "ulang konsep inti topik ${topic.topic} lalu coba 2-3 soal mudah";
    }
    if (accuracy < 0.8) {
      return "latihan 3 soal lagi di topik ${topic.topic}";
    }
    final difficulty = _difficultyLabel(topic.currentDifficulty);
    return "coba soal tingkat $difficulty untuk tantangan berikutnya";
  }

  String _nextStepForScore(int score, String? chapterName) {
    final label = chapterName == null || chapterName.trim().isEmpty ? "materi ini" : "bab ${chapterName.trim()}";
    if (score >= 85) {
      return "lanjut ke materi berikutnya atau coba soal lebih sulit di $label";
    }
    if (score >= 60) {
      return "ulang bagian yang lemah di $label lalu latihan 3-5 soal";
    }
    return "ulang konsep inti di $label lalu latihan dasar sebelum lanjut";
  }

  String _difficultyLabel(QuizDifficulty difficulty) {
    return switch (difficulty) {
      QuizDifficulty.easy => 'mudah',
      QuizDifficulty.medium => 'sedang',
      QuizDifficulty.hard => 'sulit',
    };
  }

  String _nextStepSentence(String nextStep) {
    final trimmed = nextStep.trim();
    if (trimmed.isEmpty) return '';
    return " Langkah berikutnya: $trimmed.";
  }

  bool _hasContextHint(String lowerPrompt) {
    final hints = [
      'bab ini',
      'bab aktif',
      'bab sekarang',
      'topik ini',
      'topik aktif',
      'materi ini',
      'bagian ini',
      'di sini',
      'course ini',
      'kursus ini',
      'materi sekarang',
      'topik sekarang',
    ];
    return hints.any(lowerPrompt.contains);
  }

  bool _matchesMaterial(List<String> promptTokens, String? materialContent) {
    final material = materialContent?.trim() ?? '';
    if (material.isEmpty || promptTokens.isEmpty) return false;
    final lower = material.toLowerCase();
    for (final t in promptTokens) {
      if (t.length < 3 && !_shortScopeTokens.contains(t)) continue;
      if (lower.contains(t)) return true;
    }
    return false;
  }

  String _outOfScopeMessage(String? chapterName) {
    final label = chapterName == null || chapterName.trim().isEmpty ? "materi yang sedang kamu buka" : "bab ${chapterName.trim()}";
    return "Pertanyaanmu di luar scope. Aku hanya bisa bantu untuk $label. Bagian mana dari $label yang ingin kamu bahas?";
  }

  bool _hasSubmission(LevelyProgress progress) {
    return progress.history.isNotEmpty || progress.attemptedTotal > 0;
  }

  bool _mentionsSubmissionType(String lowerPrompt) {
    return _submissionTypeHints.any(lowerPrompt.contains);
  }

  bool _isPerformanceRequest(String lowerPrompt) {
    if (_performanceQuestionPattern.hasMatch(lowerPrompt)) return true;
    return _selfPerformancePattern.hasMatch(lowerPrompt);
  }

  List<String> _tokenize(String text) {
    final lower = text.toLowerCase();
    final raw = lower.split(RegExp(r'[^a-z0-9]+'));
    final stopwords = <String>{
      'yang',
      'dan',
      'atau',
      'dari',
      'ke',
      'di',
      'untuk',
      'pada',
      'dengan',
      'itu',
      'ini',
      'jadi',
      'akan',
      'dalam',
      'sebagai',
      'apa',
      'bagaimana',
      'jelaskan',
      'ringkas',
      'contoh',
      'bisa',
      'tolong',
      'mohon',
      'lagi',
      'bab',
      'topik',
      'materi',
    };
    return raw.where((t) => t.length >= 2 && !stopwords.contains(t)).toList();
  }

  static const Set<String> _shortScopeTokens = {'ui', 'ux', 'ai', 'ml'};
  static const List<String> _submissionTypeHints = [
    'quiz',
    'kuis',
    'assessment',
    'asesmen',
    'assignment',
    'tugas',
  ];
  static final RegExp _performanceQuestionPattern = RegExp(
    r'(gimana|bagaimana|seberapa|cek|lihat|review|evaluasi)\s+(progres|progress|performa|hasil|nilai|skor|score|kemajuan|akurasi|poin|streak)',
  );
  static final RegExp _selfPerformancePattern = RegExp(
    r'(progres|progress|performa|hasil|nilai|skor|score|kemajuan|akurasi|poin|streak)(ku|\s*(saya|aku))',
  );

  String limitSentences(String text, {int maxSentences = 6}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final parts = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
    if (parts.length <= maxSentences) return trimmed;
    return parts.take(maxSentences).join(' ').trim();
  }
}

class LevelyCompanion {
  final bool _lockEngine;
  LevelyEngine _engine;
  int _engineRevision;
  final LevelyCompanionObserver observer;
  final LevelyCompanionFeedback feedback;

  LevelyCompanion({
    LevelyEngine? engine,
    LevelyCompanionObserver? observer,
    LevelyCompanionFeedback? feedback,
  })  : _lockEngine = engine != null,
        _engine = engine ?? _buildEngine(),
        _engineRevision = LevelyRuntimeConfig.revision,
        observer = observer ?? LevelyCompanionObserver(),
        feedback = feedback ?? LevelyCompanionFeedback();

  LevelyEngine get engine {
    if (!_lockEngine && _engineRevision != LevelyRuntimeConfig.revision) {
      _engine = _buildEngine();
      _engineRevision = LevelyRuntimeConfig.revision;
    }
    return _engine;
  }

  static LevelyEngine _buildEngine() {
    final allowOverrides = kDebugMode;
    final overrides = allowOverrides ? LevelyRuntimeConfig.overrides : const LevelyLlmOverrides();
    final config = LevelyLlmConfigResolver.resolve(
      allowOverrides: allowOverrides,
      overrides: overrides,
    );

    if (!config.enabled) {
      if (kDebugMode) {
        debugPrint('Levely LLM disabled: no API key set.');
      }
      return LevelyEngine();
    }

    if (kDebugMode) {
      debugPrint('Levely LLM enabled with provider: gemini');
      debugPrint('Levely LLM model: ${config.model}');
      debugPrint('Levely LLM base URL: ${config.baseUrl}');
    }
    return LevelyEngine(
      llm: GeminiApiClient(
        apiKey: config.apiKey,
        model: config.model,
        baseUrl: config.baseUrl,
      ),
    );
  }

  Future<LevelyProgress> loadProgress() => engine.loadProgress();

  Future<void> saveProgress(LevelyProgress progress) => engine.saveProgress(progress);

  Future<LevelyCompanionAutoFeedback> observeQuiz({
    required LevelyProgress progress,
    required QuizQuestion question,
    required int selectedIndex,
    required DateTime now,
  }) async {
    final observation = observer.observeQuiz(
      progress: progress,
      question: question,
      selectedIndex: selectedIndex,
      now: now,
    );
    final text = feedback.quizFeedback(
      observation: observation,
      question: question,
      selectedIndex: selectedIndex,
      pointsDelta: observation.pointsDelta ?? 0,
    );
    final updated = observation.after.copyWith(lastFeedback: text, lastFeedbackAt: now);
    await saveProgress(updated);
    return LevelyCompanionAutoFeedback(
      progress: updated,
      event: observation.event,
      pointsDelta: observation.pointsDelta,
      newlyUnlocked: observation.newlyUnlocked,
      feedback: text,
    );
  }

  Future<LevelyCompanionAutoFeedback> observeAssessment({
    required LevelyProgress progress,
    required int correct,
    required int attempted,
    required int score,
    required DateTime now,
    String? chapterName,
    String? referenceId,
  }) async {
    final observation = observer.observeAssessment(
      progress: progress,
      correct: correct,
      attempted: attempted,
      score: score,
      now: now,
      topic: chapterName,
      referenceId: referenceId,
    );
    final text = feedback.assessmentFeedback(
      observation: observation,
      correct: correct,
      attempted: attempted,
      score: score,
      chapterName: chapterName,
    );
    final updated = observation.after.copyWith(lastFeedback: text, lastFeedbackAt: now);
    await saveProgress(updated);
    return LevelyCompanionAutoFeedback(
      progress: updated,
      event: observation.event,
      feedback: text,
    );
  }

  Future<LevelyCompanionAutoFeedback> observeAssignment({
    required LevelyProgress progress,
    required DateTime now,
    int? score,
    String? chapterName,
    String? referenceId,
  }) async {
    final observation = observer.observeAssignment(
      progress: progress,
      now: now,
      score: score,
      topic: chapterName,
      referenceId: referenceId,
    );
    final text = feedback.assignmentFeedback(
      observation: observation,
      score: score,
      chapterName: chapterName,
    );
    final updated = observation.after.copyWith(lastFeedback: text, lastFeedbackAt: now);
    await saveProgress(updated);
    return LevelyCompanionAutoFeedback(
      progress: updated,
      event: observation.event,
      feedback: text,
    );
  }

  Future<String> quickAsk({
    required String prompt,
    required LevelyProgress progress,
    required List<LevelyChatMessage> history,
    int? courseId,
    int? level,
    String? chapterName,
    String? materialContent,
  }) async {
    final llm = engine.llm;
    if (llm == null) {
      if (kDebugMode) {
        debugPrint('Levely QuickAsk fallback: LLM disabled.');
      }
      final fallback = feedback.quickAskFallback(prompt: prompt, progress: progress, chapterName: chapterName);
      return feedback.limitSentences(fallback);
    }

    try {
      final snippet = (materialContent == null || materialContent.trim().isEmpty)
          ? ''
          : LevelyRag.buildSnippet(material: materialContent);
      final reply = await engine.answerChat(
        userMessage: prompt,
        progress: progress,
        courseId: courseId,
        level: level,
        chapterName: chapterName,
        materialSnippet: snippet,
        history: history,
      );
      return feedback.limitSentences(reply);
    } catch (err, stack) {
      if (kDebugMode) {
        debugPrint('Levely QuickAsk LLM error: $err');
        debugPrint('$stack');
      }
      final fallback = feedback.quickAskFallback(prompt: prompt, progress: progress, chapterName: chapterName);
      return feedback.limitSentences(fallback);
    }
  }
}
