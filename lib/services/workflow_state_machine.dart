class WorkflowStateMachine {
  WorkflowStateMachine._();

  static const Set<String> _pending = {
    'bekleyen',
    'beklemede',
    'atandi',
    'kontrol_bekliyor',
  };

  static const Set<String> _approved = {
    'onaylandi',
    'kabul_edildi',
    'kalite_onay',
  };

  static const Set<String> _inProgress = {
    'uretimde',
    'baslatildi',
    'baslandi',
    'devam_ediyor',
    'kontrolde',
    'kontrol_ediliyor',
    'sevk_ediliyor',
    'kismen_sevk',
  };

  static const Set<String> _partial = {
    'kismi_tamamlandi',
  };

  static const Set<String> _completed = {
    'tamamlandi',
    'sevk_edildi',
  };

  static const Set<String> _rejected = {
    'reddedildi',
    'kalite_red',
    'kalite_reddedildi',
  };

  static const Set<String> _cancelled = {
    'iptal',
    'iptal_edildi',
  };

  static String normalize(String? status) {
    if (status == null || status.trim().isEmpty) {
      return '';
    }
    return status
        .trim()
        .toLowerCase()
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  static bool canTransition({
    required String? fromStatus,
    required String toStatus,
    String? context,
  }) {
    final from = normalize(fromStatus);
    final to = normalize(toStatus);

    if (to.isEmpty) return false;
    if (from == to) return true;

    if (from.isEmpty) {
      return _pending.contains(to) || _approved.contains(to);
    }

    if (_pending.contains(from)) {
      return _approved.contains(to) ||
          _inProgress.contains(to) ||
          _rejected.contains(to) ||
          _cancelled.contains(to);
    }

    if (_approved.contains(from)) {
      return _inProgress.contains(to) ||
          _partial.contains(to) ||
          _completed.contains(to) ||
          _rejected.contains(to) ||
          _cancelled.contains(to);
    }

    if (_inProgress.contains(from)) {
      return _partial.contains(to) ||
          _completed.contains(to) ||
          _rejected.contains(to) ||
          _inProgress.contains(to) ||
          _cancelled.contains(to);
    }

    if (_partial.contains(from)) {
      return _inProgress.contains(to) ||
          _partial.contains(to) ||
          _completed.contains(to) ||
          _rejected.contains(to) ||
          _cancelled.contains(to);
    }

    if (_rejected.contains(from)) {
      return _pending.contains(to) || _approved.contains(to);
    }

    if (_completed.contains(from)) {
      return _approved.contains(to) || _inProgress.contains(to);
    }

    if (_cancelled.contains(from)) {
      return false;
    }

    return false;
  }

  static void ensureTransition({
    required String? fromStatus,
    required String toStatus,
    String? context,
  }) {
    if (canTransition(
      fromStatus: fromStatus,
      toStatus: toStatus,
      context: context,
    )) {
      return;
    }

    final source =
        fromStatus == null || fromStatus.trim().isEmpty ? 'bos' : fromStatus;
    final where = context == null ? '' : ' ($context)';
    throw Exception('Gecersiz durum gecisi$where: $source -> $toStatus');
  }

  static bool isCompleted(String? status) {
    return _completed.contains(normalize(status));
  }

  static bool isRejected(String? status) {
    return _rejected.contains(normalize(status));
  }
}
