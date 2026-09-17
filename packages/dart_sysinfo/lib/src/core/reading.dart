/// Typed readings for potentially platform-specific fields (PRD §5.2).
library;

import 'package:meta/meta.dart';

/// Unsupported, not-yet-measured, and failed reads are **not** interchangeable
/// nulls. Use a sealed wrapper with exactly three variants for this major
/// version.
sealed class Reading<T> {
  const Reading();

  bool get isValue => this is ReadingValue<T>;
  bool get isUnsupported => this is ReadingUnsupported<T>;
  bool get isUnavailable => this is ReadingUnavailable<T>;

  T? get valueOrNull => switch (this) {
        ReadingValue<T>(:final value) => value,
        _ => null,
      };

  /// Returns the value if present, otherwise [fallback].
  T orElse(T fallback) => valueOrNull ?? fallback;

  /// Exhaustive combinator. Safe to rely on forever within this major
  /// version: see the closed-variant policy in PRD §5.2.
  R when<R>({
    required R Function(T value) value,
    required R Function(String? reason) unsupported,
    required R Function(String? reason) unavailable,
  }) =>
      switch (this) {
        ReadingValue<T>(value: final v) => value(v),
        ReadingUnsupported<T>(reason: final r) => unsupported(r),
        ReadingUnavailable<T>(reason: final r) => unavailable(r),
      };

  /// Partial combinator; anything omitted falls back to [orElse].
  R maybeWhen<R>({
    R Function(T value)? value,
    R Function(String? reason)? unsupported,
    R Function(String? reason)? unavailable,
    // ignore: always_put_required_named_parameters_first — PRD §5.2 signature
    required R Function() orElse,
  }) =>
      switch (this) {
        ReadingValue<T>(value: final v) =>
          value != null ? value(v) : orElse(),
        ReadingUnsupported<T>(reason: final r) =>
          unsupported != null ? unsupported(r) : orElse(),
        ReadingUnavailable<T>(reason: final r) =>
          unavailable != null ? unavailable(r) : orElse(),
      };
}

/// A real value returned by the OS for this field.
@immutable
final class ReadingValue<T> extends Reading<T> {
  const ReadingValue(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingValue<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ReadingValue($value)';
}

/// This platform / build profile can never report this field
/// (e.g. iOS App Store profile, missing sensor, Web — see PRD §1.6).
@immutable
final class ReadingUnsupported<T> extends Reading<T> {
  const ReadingUnsupported({this.reason});

  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingUnsupported<T> && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'ReadingUnsupported(reason: $reason)';
}

/// Supported in principle, but this attempt failed or is not yet measured
/// (permission missing, transient OS error, first sample of a delta metric).
@immutable
final class ReadingUnavailable<T> extends Reading<T> {
  const ReadingUnavailable({this.reason});

  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingUnavailable<T> && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'ReadingUnavailable(reason: $reason)';
}
