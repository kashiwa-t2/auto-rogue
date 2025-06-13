extends RefCounted
class_name GameLogger

## 統一ログシステム
## 全クラス共通のログ機能を提供

enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR
}

## デバッグログ出力
static func log_debug(tag: String, message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[%s] %s" % [tag, message])

## 情報ログ出力
static func log_info(tag: String, message: String) -> void:
	print("[%s] INFO: %s" % [tag, message])

## 警告ログ出力
static func log_warning(tag: String, message: String) -> void:
	print("[%s] WARNING: %s" % [tag, message])

## エラーログ出力
static func log_error(tag: String, message: String) -> void:
	print("[%s] ERROR: %s" % [tag, message])

## 条件付きログ出力
static func log_if(condition: bool, level: LogLevel, tag: String, message: String) -> void:
	if not condition:
		return
	
	match level:
		LogLevel.DEBUG:
			log_debug(tag, message)
		LogLevel.INFO:
			log_info(tag, message)
		LogLevel.WARNING:
			log_warning(tag, message)
		LogLevel.ERROR:
			log_error(tag, message)

## フォーマット付きデバッグログ
static func log_debug_f(tag: String, format: String, args: Array) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[%s] %s" % [tag, format % args])

## フォーマット付きエラーログ
static func log_error_f(tag: String, format: String, args: Array) -> void:
	print("[%s] ERROR: %s" % [tag, format % args])