-- ============================================================================
-- EMS 能源管理系統 - 完整資料庫 Schema
-- 光儲直柔微電網園區 + 建築能碳平台
-- ============================================================================
-- 資料庫引擎: MySQL 8.0
-- 字符集: utf8mb4_unicode_ci
-- 模組: M1~M10 (共 10 個功能模組)
-- 產生日期: 2026-04-03
-- ============================================================================

CREATE DATABASE IF NOT EXISTS ems_microgrid
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE ems_microgrid;

-- ============================================================================
-- Part 1-3: M1 基礎平台 / M2 數據採集 / M3 監控
-- ============================================================================

-- ============================================================================
-- EMS (Energy Management System) for Microgrid Campus - MySQL 8.0 Schema
-- Parts 1-3: M1 (基礎平台 & DevOps), M2 (數據採集 & 協議接入), M3 (監控)
-- ============================================================================
-- Engine: InnoDB, Charset: utf8mb4, Collation: utf8mb4_unicode_ci
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

-- ============================================================================
-- M1: 基礎平台 & DevOps
-- ============================================================================

-- WI-1.1: 微服務框架

CREATE TABLE IF NOT EXISTS sys_user (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '用戶ID',
  username VARCHAR(64) NOT NULL UNIQUE COMMENT '用戶名',
  password_hash VARCHAR(255) NOT NULL COMMENT '密碼雜湊值',
  email VARCHAR(128) COMMENT '電子郵件',
  phone VARCHAR(20) COMMENT '電話號碼',
  avatar VARCHAR(255) COMMENT '頭像URL',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '用戶狀態: active/inactive/locked',
  last_login_at DATETIME COMMENT '最後登入時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_username (username),
  KEY idx_email (email),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統用戶表';

CREATE TABLE IF NOT EXISTS sys_role (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '角色ID',
  name VARCHAR(128) NOT NULL UNIQUE COMMENT '角色名稱',
  code VARCHAR(64) NOT NULL UNIQUE COMMENT '角色代碼',
  description VARCHAR(255) COMMENT '角色描述',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '角色狀態: active/inactive',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_code (code),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統角色表';

CREATE TABLE IF NOT EXISTS sys_menu (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '菜單ID',
  parent_id BIGINT COMMENT '父菜單ID',
  name VARCHAR(128) NOT NULL COMMENT '菜單名稱',
  path VARCHAR(255) COMMENT '菜單路徑',
  icon VARCHAR(64) COMMENT '菜單圖標',
  sort INT DEFAULT 0 COMMENT '排序順序',
  type VARCHAR(32) NOT NULL COMMENT '菜單類型: directory/menu/button',
  permission VARCHAR(255) COMMENT '權限標識',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '菜單狀態: active/inactive',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_parent_id (parent_id),
  KEY idx_type (type),
  KEY idx_status (status),
  CONSTRAINT fk_menu_parent FOREIGN KEY (parent_id) REFERENCES sys_menu(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統菜單表';

CREATE TABLE IF NOT EXISTS sys_config (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '配置ID',
  config_key VARCHAR(128) NOT NULL UNIQUE COMMENT '配置鍵',
  config_value LONGTEXT COMMENT '配置值',
  description VARCHAR(255) COMMENT '配置描述',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '配置狀態: active/inactive',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_config_key (config_key),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統配置表';

CREATE TABLE IF NOT EXISTS sys_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '日誌ID',
  user_id BIGINT COMMENT '用戶ID',
  module VARCHAR(128) COMMENT '模組名稱',
  action VARCHAR(128) COMMENT '操作名稱',
  ip VARCHAR(45) COMMENT '客戶端IP地址',
  user_agent VARCHAR(255) COMMENT '用戶代理',
  request_body LONGTEXT COMMENT '請求體',
  response_code INT COMMENT '響應碼',
  duration_ms INT COMMENT '執行時間(毫秒)',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_user_id (user_id),
  KEY idx_module (module),
  KEY idx_created_at (created_at),
  CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統日誌表';

-- WI-1.3: RBAC

CREATE TABLE IF NOT EXISTS sys_permission (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '權限ID',
  parent_id BIGINT COMMENT '父權限ID',
  name VARCHAR(128) NOT NULL COMMENT '權限名稱',
  url VARCHAR(255) COMMENT '權限URL',
  method VARCHAR(32) COMMENT '請求方法: GET/POST/PUT/DELETE/PATCH',
  type VARCHAR(32) NOT NULL COMMENT '權限類型: menu/api/button',
  sort INT DEFAULT 0 COMMENT '排序順序',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '權限狀態: active/inactive',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_parent_id (parent_id),
  KEY idx_type (type),
  KEY idx_status (status),
  CONSTRAINT fk_permission_parent FOREIGN KEY (parent_id) REFERENCES sys_permission(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統權限表';

CREATE TABLE IF NOT EXISTS sys_user_role (
  user_id BIGINT NOT NULL COMMENT '用戶ID',
  role_id BIGINT NOT NULL COMMENT '角色ID',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  PRIMARY KEY (user_id, role_id),
  KEY idx_role_id (role_id),
  CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES sys_role(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用戶角色關聯表';

CREATE TABLE IF NOT EXISTS sys_role_permission (
  role_id BIGINT NOT NULL COMMENT '角色ID',
  permission_id BIGINT NOT NULL COMMENT '權限ID',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  PRIMARY KEY (role_id, permission_id),
  KEY idx_permission_id (permission_id),
  CONSTRAINT fk_role_perm_role FOREIGN KEY (role_id) REFERENCES sys_role(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_role_perm_permission FOREIGN KEY (permission_id) REFERENCES sys_permission(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色權限關聯表';

-- WI-1.4: 安全模組

CREATE TABLE IF NOT EXISTS sys_security_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '安全日誌ID',
  event_type VARCHAR(64) NOT NULL COMMENT '事件類型',
  severity VARCHAR(32) NOT NULL COMMENT '事件級別: info/warning/critical/fatal',
  source_ip VARCHAR(45) COMMENT '來源IP地址',
  user_id BIGINT COMMENT '用戶ID',
  detail LONGTEXT COMMENT '事件詳情',
  resolved TINYINT(1) DEFAULT 0 COMMENT '是否已解決',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_event_type (event_type),
  KEY idx_severity (severity),
  KEY idx_user_id (user_id),
  KEY idx_created_at (created_at),
  CONSTRAINT fk_sec_log_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統安全日誌表';

CREATE TABLE IF NOT EXISTS sys_ip_blacklist (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '黑名單ID',
  ip_address VARCHAR(45) NOT NULL UNIQUE COMMENT 'IP地址',
  reason VARCHAR(255) COMMENT '黑名單原因',
  expire_at DATETIME COMMENT '過期時間',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '狀態: active/inactive/expired',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_ip_address (ip_address),
  KEY idx_status (status),
  KEY idx_expire_at (expire_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IP黑名單表';

-- WI-1.5: 部署方案

CREATE TABLE IF NOT EXISTS ops_deploy_record (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '部署記錄ID',
  service_name VARCHAR(128) NOT NULL COMMENT '服務名稱',
  version VARCHAR(64) NOT NULL COMMENT '部署版本',
  environment VARCHAR(32) NOT NULL COMMENT '部署環境: dev/test/staging/prod',
  deploy_type VARCHAR(32) COMMENT '部署類型: blue_green/canary/rolling',
  status VARCHAR(32) NOT NULL DEFAULT 'pending' COMMENT '部署狀態: pending/in_progress/success/failed/rollback',
  operator_id BIGINT COMMENT '操作員ID',
  rollback_version VARCHAR(64) COMMENT '回滾版本',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_service_name (service_name),
  KEY idx_environment (environment),
  KEY idx_status (status),
  KEY idx_operator_id (operator_id),
  CONSTRAINT fk_deploy_operator FOREIGN KEY (operator_id) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運維部署記錄表';

CREATE TABLE IF NOT EXISTS ops_alert_rule (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '告警規則ID',
  rule_name VARCHAR(128) NOT NULL COMMENT '規則名稱',
  metric_name VARCHAR(128) NOT NULL COMMENT '指標名稱',
  threshold DECIMAL(18,4) COMMENT '告警閾值',
  operator VARCHAR(32) COMMENT '比較操作符: eq/ne/gt/gte/lt/lte',
  severity VARCHAR(32) NOT NULL COMMENT '告警級別: info/warning/critical/fatal',
  notify_channel VARCHAR(255) COMMENT '通知渠道: email/sms/webhook',
  enabled TINYINT(1) DEFAULT 1 COMMENT '是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_rule_name (rule_name),
  KEY idx_metric_name (metric_name),
  KEY idx_severity (severity),
  KEY idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運維告警規則表';

-- ============================================================================
-- M2: 數據採集 & 協議接入
-- ============================================================================

-- WI-2.1: Modbus

CREATE TABLE IF NOT EXISTS gateway_info (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '網關ID',
  gateway_name VARCHAR(128) NOT NULL COMMENT '網關名稱',
  gateway_code VARCHAR(64) NOT NULL UNIQUE COMMENT '網關代碼',
  model VARCHAR(64) COMMENT '網關型號',
  firmware_version VARCHAR(32) COMMENT '固件版本',
  ip_address VARCHAR(45) NOT NULL COMMENT 'IP地址',
  mac_address VARCHAR(17) COMMENT 'MAC地址',
  site_id BIGINT COMMENT '站點ID',
  status VARCHAR(32) NOT NULL DEFAULT 'online' COMMENT '網關狀態: online/offline/error',
  last_heartbeat_at DATETIME COMMENT '最後心跳時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_gateway_code (gateway_code),
  KEY idx_ip_address (ip_address),
  KEY idx_site_id (site_id),
  KEY idx_status (status),
  KEY idx_last_heartbeat_at (last_heartbeat_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='能源網關信息表';

CREATE TABLE IF NOT EXISTS device_info (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '設備ID',
  device_name VARCHAR(128) NOT NULL COMMENT '設備名稱',
  device_code VARCHAR(64) NOT NULL UNIQUE COMMENT '設備代碼',
  device_type VARCHAR(64) NOT NULL COMMENT '設備類型: inverter/bms/pcs/pv/load/meter',
  protocol_type VARCHAR(32) NOT NULL COMMENT '協議類型: modbus/iec104/iec61850/iec103/mqtt',
  ip_address VARCHAR(45) COMMENT 'IP地址',
  port INT COMMENT '端口號',
  slave_id INT COMMENT 'Modbus從機ID',
  gateway_id BIGINT COMMENT '所屬網關ID',
  site_id BIGINT COMMENT '站點ID',
  status VARCHAR(32) NOT NULL DEFAULT 'online' COMMENT '設備狀態: online/offline/error/maintenance',
  last_online_at DATETIME COMMENT '最後在線時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_device_code (device_code),
  KEY idx_device_type (device_type),
  KEY idx_protocol_type (protocol_type),
  KEY idx_gateway_id (gateway_id),
  KEY idx_site_id (site_id),
  KEY idx_status (status),
  CONSTRAINT fk_device_gateway FOREIGN KEY (gateway_id) REFERENCES gateway_info(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備信息表';

CREATE TABLE IF NOT EXISTS device_register_map (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '寄存器映射ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  register_name VARCHAR(128) NOT NULL COMMENT '寄存器名稱',
  register_address INT NOT NULL COMMENT '寄存器地址',
  function_code INT COMMENT 'Modbus功能碼',
  data_type VARCHAR(32) COMMENT '數據類型: int16/uint16/int32/uint32/float/double',
  scale_factor DECIMAL(18,6) COMMENT '縮放因子',
  unit VARCHAR(32) COMMENT '單位',
  description VARCHAR(255) COMMENT '描述',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_device_id (device_id),
  KEY idx_register_address (register_address),
  UNIQUE KEY uk_device_register (device_id, register_address),
  CONSTRAINT fk_register_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Modbus寄存器映射表';

CREATE TABLE IF NOT EXISTS collect_task (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '採集任務ID',
  task_name VARCHAR(128) NOT NULL COMMENT '任務名稱',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  protocol_type VARCHAR(32) NOT NULL COMMENT '協議類型',
  cron_expression VARCHAR(64) COMMENT 'Cron表達式',
  timeout_ms INT DEFAULT 5000 COMMENT '超時時間(毫秒)',
  retry_count INT DEFAULT 3 COMMENT '重試次數',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '任務狀態: active/inactive/error',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_device_id (device_id),
  KEY idx_protocol_type (protocol_type),
  KEY idx_status (status),
  CONSTRAINT fk_collect_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='數據採集任務表';

-- WI-2.2: IEC 104/61850/103

CREATE TABLE IF NOT EXISTS iec104_point_table (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '信息對象ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  ioa_address INT NOT NULL COMMENT 'IEC104 IOA地址',
  point_name VARCHAR(128) NOT NULL COMMENT '信息對象名稱',
  point_type VARCHAR(32) NOT NULL COMMENT '信息對象類型: telemetry/teleindication/telecontrol',
  data_type VARCHAR(32) COMMENT '數據類型: int/float/string/boolean',
  scale_factor DECIMAL(18,6) COMMENT '縮放因子',
  unit VARCHAR(32) COMMENT '單位',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_device_id (device_id),
  KEY idx_ioa_address (ioa_address),
  KEY idx_point_type (point_type),
  UNIQUE KEY uk_device_ioa (device_id, ioa_address),
  CONSTRAINT fk_iec104_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IEC104信息對象表';

CREATE TABLE IF NOT EXISTS iec104_soe_event (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'SOE事件ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  ioa_address INT NOT NULL COMMENT 'IOA地址',
  event_type VARCHAR(64) COMMENT '事件類型',
  value VARCHAR(64) COMMENT '事件值',
  quality_flag INT COMMENT '品質標誌',
  timestamp_ms BIGINT COMMENT '毫秒級時間戳',
  received_at DATETIME NOT NULL COMMENT '接收時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_device_id (device_id),
  KEY idx_received_at (received_at),
  KEY idx_timestamp_ms (timestamp_ms),
  CONSTRAINT fk_soe_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IEC104 SOE事件表';

-- WI-2.3: MQTT & 其他協議

CREATE TABLE IF NOT EXISTS mqtt_client_status (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'MQTT客戶端ID',
  client_id VARCHAR(128) NOT NULL UNIQUE COMMENT '客戶端ID',
  device_id BIGINT COMMENT '關聯設備ID',
  topic VARCHAR(255) COMMENT 'MQTT主題',
  connected TINYINT(1) DEFAULT 0 COMMENT '連接狀態',
  last_msg_at DATETIME COMMENT '最後消息時間',
  ip_address VARCHAR(45) COMMENT 'IP地址',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_client_id (client_id),
  KEY idx_device_id (device_id),
  KEY idx_connected (connected),
  CONSTRAINT fk_mqtt_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MQTT客戶端狀態表';

CREATE TABLE IF NOT EXISTS protocol_adapter_config (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '適配器配置ID',
  adapter_name VARCHAR(128) NOT NULL UNIQUE COMMENT '適配器名稱',
  protocol_type VARCHAR(32) NOT NULL COMMENT '協議類型: modbus/iec104/mqtt/iec61850/iec103',
  config_json LONGTEXT COMMENT '配置JSON',
  enabled TINYINT(1) DEFAULT 1 COMMENT '是否啟用',
  description VARCHAR(255) COMMENT '描述',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_protocol_type (protocol_type),
  KEY idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='協議適配器配置表';

-- WI-2.4: 能源網關

CREATE TABLE IF NOT EXISTS gateway_heartbeat (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '心跳記錄ID',
  gateway_id BIGINT NOT NULL COMMENT '網關ID',
  cpu_usage DECIMAL(5,2) COMMENT 'CPU使用率(%)',
  memory_usage DECIMAL(5,2) COMMENT '內存使用率(%)',
  disk_usage DECIMAL(5,2) COMMENT '磁盤使用率(%)',
  temperature DECIMAL(6,2) COMMENT '溫度(℃)',
  uptime_seconds BIGINT COMMENT '運行時長(秒)',
  reported_at DATETIME NOT NULL COMMENT '上報時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_gateway_id (gateway_id),
  KEY idx_reported_at (reported_at),
  CONSTRAINT fk_heartbeat_gateway FOREIGN KEY (gateway_id) REFERENCES gateway_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='網關心跳記錄表';

CREATE TABLE IF NOT EXISTS ota_version (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '版本ID',
  version_name VARCHAR(64) NOT NULL COMMENT '版本名稱',
  version_code VARCHAR(32) NOT NULL UNIQUE COMMENT '版本號',
  firmware_url VARCHAR(255) NOT NULL COMMENT '固件下載URL',
  file_size BIGINT COMMENT '文件大小(字節)',
  checksum VARCHAR(128) COMMENT '文件校驗和',
  release_note LONGTEXT COMMENT '發佈說明',
  status VARCHAR(32) NOT NULL DEFAULT 'draft' COMMENT '版本狀態: draft/released/deprecated',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_version_code (version_code),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OTA固件版本表';

CREATE TABLE IF NOT EXISTS ota_upgrade_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '升級日誌ID',
  gateway_id BIGINT NOT NULL COMMENT '網關ID',
  from_version VARCHAR(32) COMMENT '源版本號',
  to_version VARCHAR(32) NOT NULL COMMENT '目標版本號',
  status VARCHAR(32) NOT NULL DEFAULT 'pending' COMMENT '升級狀態: pending/in_progress/success/failed',
  started_at DATETIME COMMENT '開始時間',
  completed_at DATETIME COMMENT '完成時間',
  error_msg VARCHAR(255) COMMENT '錯誤信息',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_gateway_id (gateway_id),
  KEY idx_status (status),
  KEY idx_started_at (started_at),
  CONSTRAINT fk_upgrade_gateway FOREIGN KEY (gateway_id) REFERENCES gateway_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OTA升級日誌表';

-- WI-2.5: 時序數據存儲

CREATE TABLE IF NOT EXISTS ts_data_quality (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '數據質量ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  metric_name VARCHAR(128) NOT NULL COMMENT '指標名稱',
  check_type VARCHAR(32) COMMENT '檢查類型: completeness/accuracy/consistency',
  quality_score DECIMAL(5,2) COMMENT '質量評分',
  missing_rate DECIMAL(5,2) COMMENT '缺失率(%)',
  anomaly_count INT COMMENT '異常值數量',
  check_time DATETIME NOT NULL COMMENT '檢查時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_device_id (device_id),
  KEY idx_check_type (check_type),
  KEY idx_check_time (check_time),
  CONSTRAINT fk_quality_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='時序數據質量表';

CREATE TABLE IF NOT EXISTS ts_archive_config (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '歸檔配置ID',
  data_source VARCHAR(128) NOT NULL COMMENT '數據源',
  retention_hot_days INT COMMENT '熱存儲保留天數',
  retention_warm_days INT COMMENT '溫存儲保留天數',
  retention_cold_days INT COMMENT '冷存儲保留天數',
  downsample_interval INT COMMENT '降採樣間隔(秒)',
  enabled TINYINT(1) DEFAULT 1 COMMENT '是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_data_source (data_source),
  KEY idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='時序數據歸檔配置表';

-- WI-2.6: 第三方對接

CREATE TABLE IF NOT EXISTS integration_partner (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '合作夥伴ID',
  partner_name VARCHAR(128) NOT NULL UNIQUE COMMENT '合作夥伴名稱',
  partner_code VARCHAR(64) NOT NULL UNIQUE COMMENT '合作夥伴代碼',
  contact_person VARCHAR(128) COMMENT '聯絡人',
  contact_email VARCHAR(128) COMMENT '聯絡郵箱',
  api_base_url VARCHAR(255) COMMENT 'API基礎URL',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '狀態: active/inactive/suspended',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_partner_code (partner_code),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='第三方集成合作夥伴表';

CREATE TABLE IF NOT EXISTS integration_api_key (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'API密鑰ID',
  partner_id BIGINT NOT NULL COMMENT '合作夥伴ID',
  api_key VARCHAR(255) NOT NULL UNIQUE COMMENT 'API密鑰',
  api_secret VARCHAR(255) COMMENT 'API密鑰密鑰',
  scope VARCHAR(255) COMMENT '權限範圍',
  expire_at DATETIME COMMENT '過期時間',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '狀態: active/revoked/expired',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_partner_id (partner_id),
  KEY idx_api_key (api_key),
  KEY idx_status (status),
  CONSTRAINT fk_apikey_partner FOREIGN KEY (partner_id) REFERENCES integration_partner(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='第三方集成API密鑰表';

CREATE TABLE IF NOT EXISTS integration_forward_rule (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '轉發規則ID',
  partner_id BIGINT NOT NULL COMMENT '合作夥伴ID',
  source_topic VARCHAR(255) NOT NULL COMMENT '源主題',
  target_url VARCHAR(255) NOT NULL COMMENT '目標URL',
  transform_config LONGTEXT COMMENT '轉換配置JSON',
  enabled TINYINT(1) DEFAULT 1 COMMENT '是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_partner_id (partner_id),
  KEY idx_source_topic (source_topic),
  KEY idx_enabled (enabled),
  CONSTRAINT fk_forward_partner FOREIGN KEY (partner_id) REFERENCES integration_partner(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='第三方集成數據轉發規則表';

-- ============================================================================
-- M3: 監控
-- ============================================================================

-- WI-3.1: 系統總覽

CREATE TABLE IF NOT EXISTS device_status_snapshot (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '設備狀態快照ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  device_type VARCHAR(64) COMMENT '設備類型',
  status VARCHAR(32) COMMENT '設備狀態',
  active_power DECIMAL(18,4) COMMENT '有功功率(kW)',
  reactive_power DECIMAL(18,4) COMMENT '無功功率(kVar)',
  voltage DECIMAL(10,2) COMMENT '電壓(V)',
  current DECIMAL(10,2) COMMENT '電流(A)',
  frequency DECIMAL(6,2) COMMENT '頻率(Hz)',
  soc DECIMAL(5,2) COMMENT '電池SOC(%)',
  temperature DECIMAL(6,2) COMMENT '溫度(℃)',
  snapshot_time DATETIME NOT NULL COMMENT '快照時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_device_id (device_id),
  KEY idx_device_type (device_type),
  KEY idx_snapshot_time (snapshot_time),
  CONSTRAINT fk_snapshot_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備狀態快照表';

CREATE TABLE IF NOT EXISTS data_metrics_daily (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '日指標ID',
  site_id BIGINT COMMENT '站點ID',
  metric_type VARCHAR(64) NOT NULL COMMENT '指標類型: generation/consumption/storage',
  metric_value DECIMAL(18,4) COMMENT '指標值',
  unit VARCHAR(32) COMMENT '單位',
  stat_date DATE NOT NULL COMMENT '統計日期',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_site_id (site_id),
  KEY idx_metric_type (metric_type),
  KEY idx_stat_date (stat_date),
  UNIQUE KEY uk_site_metric_date (site_id, metric_type, stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日數據指標表';

-- WI-3.2: 微電網拓撲

CREATE TABLE IF NOT EXISTS topology_config (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '拓撲配置ID',
  site_id BIGINT COMMENT '站點ID',
  topology_name VARCHAR(128) NOT NULL COMMENT '拓撲名稱',
  layout_json LONGTEXT COMMENT '拓撲佈局JSON',
  version INT DEFAULT 1 COMMENT '配置版本',
  is_active TINYINT(1) DEFAULT 1 COMMENT '是否為活躍拓撲',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_site_id (site_id),
  KEY idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='微電網拓撲配置表';

CREATE TABLE IF NOT EXISTS device_connection (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '設備連接ID',
  topology_id BIGINT NOT NULL COMMENT '拓撲配置ID',
  from_device_id BIGINT NOT NULL COMMENT '源設備ID',
  to_device_id BIGINT NOT NULL COMMENT '目標設備ID',
  connection_type VARCHAR(32) COMMENT '連接類型: ac/dc/bus',
  cable_spec VARCHAR(128) COMMENT '電纜規格',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_topology_id (topology_id),
  KEY idx_from_device_id (from_device_id),
  KEY idx_to_device_id (to_device_id),
  CONSTRAINT fk_conn_topology FOREIGN KEY (topology_id) REFERENCES topology_config(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_conn_from_device FOREIGN KEY (from_device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_conn_to_device FOREIGN KEY (to_device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備連接關係表';

CREATE TABLE IF NOT EXISTS power_flow_snapshot (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '功率流快照ID',
  topology_id BIGINT NOT NULL COMMENT '拓撲配置ID',
  from_device_id BIGINT NOT NULL COMMENT '源設備ID',
  to_device_id BIGINT NOT NULL COMMENT '目標設備ID',
  active_power DECIMAL(18,4) COMMENT '有功功率(kW)',
  reactive_power DECIMAL(18,4) COMMENT '無功功率(kVar)',
  direction VARCHAR(32) COMMENT '功率方向: forward/reverse',
  snapshot_time DATETIME NOT NULL COMMENT '快照時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_topology_id (topology_id),
  KEY idx_from_device_id (from_device_id),
  KEY idx_snapshot_time (snapshot_time),
  CONSTRAINT fk_flow_topology FOREIGN KEY (topology_id) REFERENCES topology_config(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='功率流快照表';

-- WI-3.3: 告警管理

CREATE TABLE IF NOT EXISTS alert_rule (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '告警規則ID',
  rule_name VARCHAR(128) NOT NULL COMMENT '規則名稱',
  rule_code VARCHAR(64) NOT NULL UNIQUE COMMENT '規則代碼',
  device_type VARCHAR(64) COMMENT '設備類型',
  metric_name VARCHAR(128) NOT NULL COMMENT '指標名稱',
  condition_operator VARCHAR(32) COMMENT '條件操作符: eq/ne/gt/gte/lt/lte',
  threshold_value DECIMAL(18,4) COMMENT '閾值',
  severity VARCHAR(32) NOT NULL COMMENT '告警級別: info/warning/critical/fatal',
  cooldown_seconds INT COMMENT '冷卻時間(秒)',
  enabled TINYINT(1) DEFAULT 1 COMMENT '是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_rule_code (rule_code),
  KEY idx_device_type (device_type),
  KEY idx_severity (severity),
  KEY idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='告警規則表';

CREATE TABLE IF NOT EXISTS alert_event (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '告警事件ID',
  alert_rule_id BIGINT NOT NULL COMMENT '告警規則ID',
  device_id BIGINT COMMENT '設備ID',
  site_id BIGINT COMMENT '站點ID',
  severity VARCHAR(32) NOT NULL COMMENT '告警級別: info/warning/critical/fatal',
  message VARCHAR(255) COMMENT '告警信息',
  value DECIMAL(18,4) COMMENT '觸發值',
  status VARCHAR(32) NOT NULL DEFAULT 'active' COMMENT '狀態: active/acknowledged/resolved',
  triggered_at DATETIME NOT NULL COMMENT '觸發時間',
  resolved_at DATETIME COMMENT '解決時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_alert_rule_id (alert_rule_id),
  KEY idx_device_id (device_id),
  KEY idx_site_id (site_id),
  KEY idx_severity (severity),
  KEY idx_status (status),
  KEY idx_triggered_at (triggered_at),
  CONSTRAINT fk_event_rule FOREIGN KEY (alert_rule_id) REFERENCES alert_rule(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_event_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='告警事件表';

CREATE TABLE IF NOT EXISTS alert_acknowledge (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '告警確認ID',
  alert_event_id BIGINT NOT NULL COMMENT '告警事件ID',
  user_id BIGINT NOT NULL COMMENT '確認用戶ID',
  note VARCHAR(255) COMMENT '確認備註',
  acknowledged_at DATETIME NOT NULL COMMENT '確認時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_alert_event_id (alert_event_id),
  KEY idx_user_id (user_id),
  CONSTRAINT fk_ack_event FOREIGN KEY (alert_event_id) REFERENCES alert_event(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ack_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='告警確認表';

CREATE TABLE IF NOT EXISTS alert_handler_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '告警處理日誌ID',
  alert_event_id BIGINT NOT NULL COMMENT '告警事件ID',
  handler_user_id BIGINT NOT NULL COMMENT '處理用戶ID',
  action VARCHAR(128) COMMENT '處理動作',
  description VARCHAR(255) COMMENT '處理描述',
  handled_at DATETIME NOT NULL COMMENT '處理時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_alert_event_id (alert_event_id),
  KEY idx_handler_user_id (handler_user_id),
  KEY idx_handled_at (handled_at),
  CONSTRAINT fk_handler_event FOREIGN KEY (alert_event_id) REFERENCES alert_event(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_handler_user FOREIGN KEY (handler_user_id) REFERENCES sys_user(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='告警處理日誌表';

CREATE TABLE IF NOT EXISTS notify_config (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '通知配置ID',
  name VARCHAR(128) NOT NULL UNIQUE COMMENT '配置名稱',
  channel_type VARCHAR(32) NOT NULL COMMENT '通知渠道: email/sms/wechat/webhook',
  channel_config_json LONGTEXT COMMENT '通道配置JSON',
  enabled TINYINT(1) DEFAULT 1 COMMENT '是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_channel_type (channel_type),
  KEY idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知配置表';

-- WI-3.4: 報表

CREATE TABLE IF NOT EXISTS report_template (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '報表模板ID',
  template_name VARCHAR(128) NOT NULL UNIQUE COMMENT '模板名稱',
  template_code VARCHAR(64) NOT NULL UNIQUE COMMENT '模板代碼',
  report_type VARCHAR(32) NOT NULL COMMENT '報表類型: daily/weekly/monthly/custom',
  config_json LONGTEXT COMMENT '模板配置JSON',
  description VARCHAR(255) COMMENT '模板描述',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_template_code (template_code),
  KEY idx_report_type (report_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='報表模板表';

CREATE TABLE IF NOT EXISTS report_task (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '報表任務ID',
  template_id BIGINT NOT NULL COMMENT '模板ID',
  params_json LONGTEXT COMMENT '報表參數JSON',
  status VARCHAR(32) NOT NULL DEFAULT 'pending' COMMENT '狀態: pending/processing/success/failed',
  file_url VARCHAR(255) COMMENT '報表文件URL',
  generated_at DATETIME COMMENT '生成時間',
  requested_by BIGINT COMMENT '申請用戶ID',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_template_id (template_id),
  KEY idx_status (status),
  KEY idx_requested_by (requested_by),
  CONSTRAINT fk_task_template FOREIGN KEY (template_id) REFERENCES report_template(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_task_user FOREIGN KEY (requested_by) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='報表生成任務表';

-- WI-3.5: 運行評價

CREATE TABLE IF NOT EXISTS evaluation_metric (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '評價指標ID',
  metric_name VARCHAR(128) NOT NULL UNIQUE COMMENT '指標名稱',
  metric_code VARCHAR(64) NOT NULL UNIQUE COMMENT '指標代碼',
  category VARCHAR(64) COMMENT '指標分類',
  unit VARCHAR(32) COMMENT '單位',
  weight DECIMAL(5,2) COMMENT '權重',
  target_value DECIMAL(18,4) COMMENT '目標值',
  formula VARCHAR(255) COMMENT '計算公式',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_metric_code (metric_code),
  KEY idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運行評價指標表';

CREATE TABLE IF NOT EXISTS evaluation_monthly_result (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '月度評價結果ID',
  site_id BIGINT COMMENT '站點ID',
  year_month VARCHAR(7) NOT NULL COMMENT '年月(YYYY-MM)',
  metric_id BIGINT NOT NULL COMMENT '評價指標ID',
  actual_value DECIMAL(18,4) COMMENT '實際值',
  score DECIMAL(5,2) COMMENT '得分',
  rank INT COMMENT '排名',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_site_id (site_id),
  KEY idx_year_month (year_month),
  KEY idx_metric_id (metric_id),
  UNIQUE KEY uk_site_month_metric (site_id, year_month, metric_id),
  CONSTRAINT fk_result_metric FOREIGN KEY (metric_id) REFERENCES evaluation_metric(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='月度運行評價結果表';

CREATE TABLE IF NOT EXISTS evaluation_report (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '評價報告ID',
  site_id BIGINT COMMENT '站點ID',
  year_month VARCHAR(7) NOT NULL COMMENT '年月(YYYY-MM)',
  total_score DECIMAL(5,2) COMMENT '總得分',
  grade VARCHAR(32) COMMENT '等級: A/B/C/D/E',
  report_file_url VARCHAR(255) COMMENT '報告文件URL',
  generated_at DATETIME COMMENT '生成時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_site_id (site_id),
  KEY idx_year_month (year_month),
  UNIQUE KEY uk_site_month (site_id, year_month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運行評價報告表';

-- WI-3.6: 移動端

CREATE TABLE IF NOT EXISTS push_device_token (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '推送設備token ID',
  user_id BIGINT NOT NULL COMMENT '用戶ID',
  device_type VARCHAR(32) COMMENT '設備類型: mobile/tablet/web',
  device_token VARCHAR(255) NOT NULL UNIQUE COMMENT '設備token',
  platform VARCHAR(32) NOT NULL COMMENT '平台: ios/android/wechat/windows',
  enabled TINYINT(1) DEFAULT 1 COMMENT '是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_user_id (user_id),
  KEY idx_platform (platform),
  KEY idx_enabled (enabled),
  CONSTRAINT fk_push_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='推送設備token表';

-- WI-3.7: 策略執行監測

CREATE TABLE IF NOT EXISTS strategy_definition (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '策略ID',
  strategy_name VARCHAR(128) NOT NULL COMMENT '策略名稱',
  strategy_code VARCHAR(64) NOT NULL UNIQUE COMMENT '策略代碼',
  strategy_type VARCHAR(32) NOT NULL COMMENT '策略類型: peak_shaving/demand_response/vpp/ev_charging',
  description VARCHAR(255) COMMENT '策略描述',
  config_json LONGTEXT COMMENT '策略配置JSON',
  priority INT DEFAULT 0 COMMENT '優先級',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_strategy_code (strategy_code),
  KEY idx_strategy_type (strategy_type),
  KEY idx_priority (priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運營策略定義表';

CREATE TABLE IF NOT EXISTS strategy_execution_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '策略執行日誌ID',
  strategy_id BIGINT NOT NULL COMMENT '策略ID',
  device_id BIGINT COMMENT '設備ID',
  planned_value DECIMAL(18,4) COMMENT '計劃值',
  actual_value DECIMAL(18,4) COMMENT '實際值',
  deviation DECIMAL(18,4) COMMENT '偏差',
  executed_at DATETIME NOT NULL COMMENT '執行時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_strategy_id (strategy_id),
  KEY idx_device_id (device_id),
  KEY idx_executed_at (executed_at),
  CONSTRAINT fk_exec_strategy FOREIGN KEY (strategy_id) REFERENCES strategy_definition(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_exec_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='策略執行日誌表';

CREATE TABLE IF NOT EXISTS anomaly_event (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '異常事件ID',
  site_id BIGINT COMMENT '站點ID',
  device_id BIGINT COMMENT '設備ID',
  event_type VARCHAR(64) NOT NULL COMMENT '事件類型',
  severity VARCHAR(32) NOT NULL COMMENT '事件級別: info/warning/critical/fatal',
  description VARCHAR(255) COMMENT '事件描述',
  root_cause VARCHAR(255) COMMENT '根本原因',
  status VARCHAR(32) NOT NULL DEFAULT 'open' COMMENT '狀態: open/acknowledged/resolved/closed',
  detected_at DATETIME NOT NULL COMMENT '檢測時間',
  resolved_at DATETIME COMMENT '解決時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_site_id (site_id),
  KEY idx_device_id (device_id),
  KEY idx_event_type (event_type),
  KEY idx_severity (severity),
  KEY idx_status (status),
  KEY idx_detected_at (detected_at),
  CONSTRAINT fk_anomaly_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='異常事件表';

CREATE TABLE IF NOT EXISTS event_trace (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '事件軌跡ID',
  anomaly_event_id BIGINT NOT NULL COMMENT '異常事件ID',
  trace_step INT COMMENT '軌跡步驟',
  description VARCHAR(255) COMMENT '軌跡描述',
  timestamp DATETIME NOT NULL COMMENT '軌跡時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_anomaly_event_id (anomaly_event_id),
  KEY idx_timestamp (timestamp),
  CONSTRAINT fk_trace_anomaly FOREIGN KEY (anomaly_event_id) REFERENCES anomaly_event(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='異常事件軌跡表';

CREATE TABLE IF NOT EXISTS device_location (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '設備位置ID',
  device_id BIGINT NOT NULL UNIQUE COMMENT '設備ID',
  site_id BIGINT COMMENT '站點ID',
  building VARCHAR(64) COMMENT '建築物',
  floor VARCHAR(32) COMMENT '樓層',
  room VARCHAR(64) COMMENT '房間',
  longitude DECIMAL(11,8) COMMENT '經度',
  latitude DECIMAL(10,8) COMMENT '緯度',
  altitude DECIMAL(10,2) COMMENT '海拔(米)',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY idx_site_id (site_id),
  KEY idx_device_id (device_id),
  CONSTRAINT fk_location_device FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備位置信息表';

SET FOREIGN_KEY_CHECKS=1;

-- ============================================================================

-- ----------------------------------------------------------------------------
-- site_metadata（場站元數據）- M5 預測算法 / 全系統共用
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS site_metadata (
  id BIGINT NOT NULL AUTO_INCREMENT COMMENT '場站ID',
  site_name VARCHAR(100) NOT NULL COMMENT '場站名稱',
  site_code VARCHAR(50) NOT NULL COMMENT '場站編碼',
  address VARCHAR(255) DEFAULT NULL COMMENT '地址',
  latitude DECIMAL(10,7) DEFAULT NULL COMMENT '緯度',
  longitude DECIMAL(10,7) DEFAULT NULL COMMENT '經度',
  timezone VARCHAR(50) DEFAULT 'Asia/Taipei' COMMENT '時區',
  climate_zone VARCHAR(50) DEFAULT NULL COMMENT '氣候區',
  installed_pv_kw DECIMAL(12,2) DEFAULT 0 COMMENT '已裝光伏容量(kW)',
  installed_battery_kwh DECIMAL(12,2) DEFAULT 0 COMMENT '已裝儲能容量(kWh)',
  building_area_sqm DECIMAL(12,2) DEFAULT NULL COMMENT '建築面積(㎡)',
  description TEXT DEFAULT NULL COMMENT '場站描述',
  status TINYINT NOT NULL DEFAULT 1 COMMENT '狀態：1啟用 0停用',
  commissioned_at DATE DEFAULT NULL COMMENT '投運日期',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  PRIMARY KEY (id),
  UNIQUE KEY uk_site_code (site_code),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='場站元數據表';


-- Part 2-3 補充: M4 核心控制 / M5 預測算法 / M6 優化調度
-- ============================================================================

-- =====================================================
-- EMS Schema Supplement: M4 (核心控制), M5 (預測算法), M6 (優化調度)
-- MySQL 8.0 DDL
-- Generated: 2026-04-03
-- =====================================================

-- =====================================================
-- M4: 核心控制 (Core Control)
-- =====================================================

-- WI-4.1: 削峰填谷 (Peak Shaving & Valley Filling)

CREATE TABLE IF NOT EXISTS `price_schedule` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `schedule_name` VARCHAR(255) NOT NULL COMMENT '價格表名稱',
  `period_type` ENUM('peak','valley','flat','sharp') NOT NULL COMMENT '周期類型：peak(峰時段),valley(谷時段),flat(平時段),sharp(尖峰)',
  `start_time` TIME NOT NULL COMMENT '開始時間',
  `end_time` TIME NOT NULL COMMENT '結束時間',
  `price_per_kwh` DECIMAL(10,4) NOT NULL COMMENT '單位電價(元/kWh)',
  `effective_date` DATE NOT NULL COMMENT '生效日期',
  `expire_date` DATE COMMENT '過期日期',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_effective_date` (`effective_date`),
  CONSTRAINT `fk_price_schedule_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電價計劃表：峰谷電價時段定義';

CREATE TABLE IF NOT EXISTS `strategy_peak_shaving_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `name` VARCHAR(255) NOT NULL COMMENT '策略名稱',
  `mode` VARCHAR(50) NOT NULL COMMENT '控制模式(manual/auto)',
  `target_power_kw` DECIMAL(12,2) NOT NULL COMMENT '目標功率(kW)',
  `soc_min` DECIMAL(5,2) NOT NULL COMMENT '最小SOC(%)',
  `soc_max` DECIMAL(5,2) NOT NULL COMMENT '最大SOC(%)',
  `enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否啟用(1=是,0=否)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_strategy_peak_shaving_config_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='削峰填谷策略配置表';

CREATE TABLE IF NOT EXISTS `charge_discharge_plan` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `plan_date` DATE NOT NULL COMMENT '計劃日期',
  `plan_type` ENUM('auto','manual') NOT NULL COMMENT '計劃類型：auto(自動),manual(手動)',
  `status` ENUM('draft','approved','executing','completed','cancelled') NOT NULL DEFAULT 'draft' COMMENT '計劃狀態',
  `created_by` BIGINT NOT NULL COMMENT '創建者ID',
  `approved_by` BIGINT COMMENT '批准者ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_plan_date` (`plan_date`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_charge_discharge_plan_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_charge_discharge_plan_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_charge_discharge_plan_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='充放電計劃表';

CREATE TABLE IF NOT EXISTS `charge_discharge_plan_segment` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `plan_id` BIGINT NOT NULL COMMENT '充放電計劃ID',
  `start_time` DATETIME NOT NULL COMMENT '開始時間',
  `end_time` DATETIME NOT NULL COMMENT '結束時間',
  `target_power_kw` DECIMAL(12,2) NOT NULL COMMENT '目標功率(kW)',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `action` ENUM('charge','discharge','idle') NOT NULL COMMENT '動作類型：charge(充電),discharge(放電),idle(待機)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_start_time` (`start_time`),
  CONSTRAINT `fk_charge_discharge_plan_segment_plan_id` FOREIGN KEY (`plan_id`) REFERENCES `charge_discharge_plan` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_charge_discharge_plan_segment_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='充放電計劃分段表';

CREATE TABLE IF NOT EXISTS `plan_execution_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `plan_id` BIGINT NOT NULL COMMENT '充放電計劃ID',
  `segment_id` BIGINT NOT NULL COMMENT '計劃分段ID',
  `actual_power_kw` DECIMAL(12,2) NOT NULL COMMENT '實際功率(kW)',
  `soc` DECIMAL(5,2) COMMENT '實際SOC(%)',
  `executed_at` DATETIME NOT NULL COMMENT '執行時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_segment_id` (`segment_id`),
  KEY `idx_executed_at` (`executed_at`),
  CONSTRAINT `fk_plan_execution_log_plan_id` FOREIGN KEY (`plan_id`) REFERENCES `charge_discharge_plan` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_plan_execution_log_segment_id` FOREIGN KEY (`segment_id`) REFERENCES `charge_discharge_plan_segment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='計劃執行日誌表';

CREATE TABLE IF NOT EXISTS `plan_deviation_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `plan_id` BIGINT NOT NULL COMMENT '充放電計劃ID',
  `segment_id` BIGINT NOT NULL COMMENT '計劃分段ID',
  `planned_power` DECIMAL(12,2) NOT NULL COMMENT '計劃功率(kW)',
  `actual_power` DECIMAL(12,2) NOT NULL COMMENT '實際功率(kW)',
  `deviation_pct` DECIMAL(5,2) NOT NULL COMMENT '偏差百分比(%)',
  `reason` VARCHAR(500) COMMENT '偏差原因',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_segment_id` (`segment_id`),
  CONSTRAINT `fk_plan_deviation_record_plan_id` FOREIGN KEY (`plan_id`) REFERENCES `charge_discharge_plan` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_plan_deviation_record_segment_id` FOREIGN KEY (`segment_id`) REFERENCES `charge_discharge_plan_segment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='計劃偏差記錄表';

CREATE TABLE IF NOT EXISTS `strategy_execution_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `strategy_type` VARCHAR(100) NOT NULL COMMENT '策略類型',
  `strategy_id` BIGINT NOT NULL COMMENT '策略ID',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `status` VARCHAR(50) NOT NULL COMMENT '執行狀態',
  `start_time` DATETIME NOT NULL COMMENT '開始時間',
  `end_time` DATETIME COMMENT '結束時間',
  `result_summary` TEXT COMMENT '結果摘要',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_strategy_type` (`strategy_type`),
  KEY `idx_start_time` (`start_time`),
  CONSTRAINT `fk_strategy_execution_record_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='策略執行記錄表';

-- WI-4.2: 防逆流 (Anti-Backflow Control)

CREATE TABLE IF NOT EXISTS `anti_backflow_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `pcc_device_id` BIGINT NOT NULL COMMENT 'PCC設備ID',
  `threshold_kw` DECIMAL(12,2) NOT NULL COMMENT '閾值功率(kW)',
  `response_time_ms` INT NOT NULL COMMENT '響應時間(毫秒)',
  `control_mode` VARCHAR(50) NOT NULL COMMENT '控制模式',
  `enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否啟用(1=是,0=否)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_pcc_device_id` (`pcc_device_id`),
  CONSTRAINT `fk_anti_backflow_config_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_anti_backflow_config_pcc_device_id` FOREIGN KEY (`pcc_device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='防逆流配置表';

CREATE TABLE IF NOT EXISTS `anti_backflow_event` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `config_id` BIGINT NOT NULL COMMENT '防逆流配置ID',
  `pcc_power_kw` DECIMAL(12,2) NOT NULL COMMENT 'PCC功率(kW)',
  `action_taken` VARCHAR(255) COMMENT '採取的動作',
  `response_time_ms` INT COMMENT '實際響應時間(毫秒)',
  `triggered_at` DATETIME NOT NULL COMMENT '觸發時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_config_id` (`config_id`),
  KEY `idx_triggered_at` (`triggered_at`),
  CONSTRAINT `fk_anti_backflow_event_config_id` FOREIGN KEY (`config_id`) REFERENCES `anti_backflow_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='防逆流事件表';

CREATE TABLE IF NOT EXISTS `anti_backflow_statistics` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `year_month` VARCHAR(7) NOT NULL COMMENT '統計年月(YYYY-MM)',
  `trigger_count` INT NOT NULL DEFAULT 0 COMMENT '觸發次數',
  `success_count` INT NOT NULL DEFAULT 0 COMMENT '成功次數',
  `effectiveness_pct` DECIMAL(5,2) COMMENT '有效性百分比(%)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_site_year_month` (`site_id`, `year_month`),
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_anti_backflow_statistics_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='防逆流統計表';

-- WI-4.3: PCS/BMS通信 (Device Communication)

CREATE TABLE IF NOT EXISTS `device_command_queue` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `command_type` VARCHAR(100) NOT NULL COMMENT '命令類型',
  `command_params_json` JSON COMMENT '命令參數(JSON)',
  `priority` INT NOT NULL DEFAULT 5 COMMENT '優先級(1-10)',
  `status` ENUM('pending','sent','executed','timeout','failed') NOT NULL DEFAULT 'pending' COMMENT '狀態',
  `sent_at` DATETIME COMMENT '發送時間',
  `timeout_at` DATETIME COMMENT '超時時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_device_id` (`device_id`),
  KEY `idx_status` (`status`),
  KEY `idx_priority` (`priority`),
  CONSTRAINT `fk_device_command_queue_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備命令隊列表';

CREATE TABLE IF NOT EXISTS `device_command_result` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `command_id` BIGINT NOT NULL COMMENT '命令ID',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `result_code` INT NOT NULL COMMENT '結果代碼',
  `result_msg` VARCHAR(500) COMMENT '結果信息',
  `executed_at` DATETIME NOT NULL COMMENT '執行時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_command_id` (`command_id`),
  KEY `idx_device_id` (`device_id`),
  CONSTRAINT `fk_device_command_result_command_id` FOREIGN KEY (`command_id`) REFERENCES `device_command_queue` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_device_command_result_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備命令結果表';

CREATE TABLE IF NOT EXISTS `device_communication_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `direction` ENUM('send','receive') NOT NULL COMMENT '通信方向：send(發送),receive(接收)',
  `protocol` VARCHAR(50) COMMENT '通信協議',
  `message_hex` LONGTEXT COMMENT '十六進制消息',
  `status` VARCHAR(50) COMMENT '狀態',
  `logged_at` DATETIME NOT NULL COMMENT '記錄時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_device_id` (`device_id`),
  KEY `idx_logged_at` (`logged_at`),
  CONSTRAINT `fk_device_communication_log_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備通信日誌表';

CREATE TABLE IF NOT EXISTS `device_heartbeat_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `heartbeat_time` DATETIME NOT NULL COMMENT '心跳時間',
  `latency_ms` INT COMMENT '延遲(毫秒)',
  `status` VARCHAR(50) COMMENT '狀態',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_device_id` (`device_id`),
  KEY `idx_heartbeat_time` (`heartbeat_time`),
  CONSTRAINT `fk_device_heartbeat_record_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備心跳記錄表';

-- WI-4.4: 保護 (Protection & Fault Management)

CREATE TABLE IF NOT EXISTS `protection_rule` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `rule_name` VARCHAR(255) NOT NULL COMMENT '規則名稱',
  `rule_code` VARCHAR(100) NOT NULL UNIQUE COMMENT '規則代碼',
  `device_type` VARCHAR(100) COMMENT '設備類型',
  `trigger_condition_json` JSON COMMENT '觸發條件(JSON)',
  `action_json` JSON COMMENT '執行動作(JSON)',
  `priority` INT NOT NULL DEFAULT 5 COMMENT '優先級(1-10)',
  `enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否啟用(1=是,0=否)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_rule_code` (`rule_code`),
  KEY `idx_device_type` (`device_type`),
  KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='保護規則表';

CREATE TABLE IF NOT EXISTS `fault_event` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `fault_type` VARCHAR(100) NOT NULL COMMENT '故障類型',
  `severity` ENUM('info','warning','critical','fatal') NOT NULL COMMENT '嚴重級別',
  `description` TEXT COMMENT '故障描述',
  `status` ENUM('active','diagnosed','resolved') NOT NULL DEFAULT 'active' COMMENT '狀態',
  `occurred_at` DATETIME NOT NULL COMMENT '發生時間',
  `resolved_at` DATETIME COMMENT '解決時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_device_id` (`device_id`),
  KEY `idx_site_id` (`site_id`),
  KEY `idx_severity` (`severity`),
  KEY `idx_status` (`status`),
  KEY `idx_occurred_at` (`occurred_at`),
  CONSTRAINT `fk_fault_event_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_fault_event_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='故障事件表';

CREATE TABLE IF NOT EXISTS `fault_diagnosis_report` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `fault_event_id` BIGINT NOT NULL COMMENT '故障事件ID',
  `diagnosis_result` TEXT COMMENT '診斷結果',
  `root_cause` TEXT COMMENT '根本原因',
  `recommendation` TEXT COMMENT '建議',
  `diagnosed_at` DATETIME NOT NULL COMMENT '診斷時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_fault_event_id` (`fault_event_id`),
  CONSTRAINT `fk_fault_diagnosis_report_fault_event_id` FOREIGN KEY (`fault_event_id`) REFERENCES `fault_event` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='故障診斷報告表';

CREATE TABLE IF NOT EXISTS `protection_action_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `rule_id` BIGINT NOT NULL COMMENT '保護規則ID',
  `fault_event_id` BIGINT NOT NULL COMMENT '故障事件ID',
  `action_type` VARCHAR(100) COMMENT '動作類型',
  `action_detail` TEXT COMMENT '動作詳情',
  `success` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否成功(1=是,0=否)',
  `executed_at` DATETIME NOT NULL COMMENT '執行時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_rule_id` (`rule_id`),
  KEY `idx_fault_event_id` (`fault_event_id`),
  KEY `idx_executed_at` (`executed_at`),
  CONSTRAINT `fk_protection_action_record_rule_id` FOREIGN KEY (`rule_id`) REFERENCES `protection_rule` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_protection_action_record_fault_event_id` FOREIGN KEY (`fault_event_id`) REFERENCES `fault_event` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='保護動作記錄表';

-- WI-4.5: 平抑波動 (Renewable Smoothing)

CREATE TABLE IF NOT EXISTS `renewable_smoothing_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `max_ramp_rate_per_min` DECIMAL(12,4) NOT NULL COMMENT '最大斜率(kW/分鐘)',
  `smoothing_window_sec` INT NOT NULL COMMENT '平滑窗口(秒)',
  `enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否啟用(1=是,0=否)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_renewable_smoothing_config_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='可再生能源平抑波動配置表';

CREATE TABLE IF NOT EXISTS `renewable_fluctuation_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `raw_power_kw` DECIMAL(12,2) NOT NULL COMMENT '原始功率(kW)',
  `smoothed_power_kw` DECIMAL(12,2) NOT NULL COMMENT '平滑功率(kW)',
  `fluctuation_pct` DECIMAL(5,2) COMMENT '波動率(%)',
  `recorded_at` DATETIME NOT NULL COMMENT '記錄時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_recorded_at` (`recorded_at`),
  CONSTRAINT `fk_renewable_fluctuation_record_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_renewable_fluctuation_record_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='可再生能源波動記錄表';

CREATE TABLE IF NOT EXISTS `renewable_smoothing_effectiveness` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `year_month` VARCHAR(7) NOT NULL COMMENT '統計年月(YYYY-MM)',
  `avg_fluctuation_before` DECIMAL(5,2) COMMENT '平抑前平均波動率(%)',
  `avg_fluctuation_after` DECIMAL(5,2) COMMENT '平抑後平均波動率(%)',
  `improvement_pct` DECIMAL(5,2) COMMENT '改善百分比(%)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_site_year_month` (`site_id`, `year_month`),
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_renewable_smoothing_effectiveness_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='可再生能源平抑波動有效性統計表';

-- WI-4.7: 光伏控制 (PV System Control)

CREATE TABLE IF NOT EXISTS `pv_system_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `pv_name` VARCHAR(255) NOT NULL COMMENT '光伏系統名稱',
  `installed_capacity_kw` DECIMAL(12,2) NOT NULL COMMENT '裝機容量(kW)',
  `inverter_count` INT NOT NULL COMMENT '逆變器數量',
  `panel_type` VARCHAR(100) COMMENT '面板類型',
  `orientation` VARCHAR(50) COMMENT '朝向',
  `tilt_angle` DECIMAL(5,2) COMMENT '傾斜角度(度)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_pv_system_config_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='光伏系統配置表';

CREATE TABLE IF NOT EXISTS `pv_performance_baseline` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `pv_system_id` BIGINT NOT NULL COMMENT '光伏系統ID',
  `month` TINYINT NOT NULL COMMENT '月份(1-12)',
  `expected_generation_kwh` DECIMAL(14,2) NOT NULL COMMENT '預期發電量(kWh)',
  `pr_ratio` DECIMAL(5,3) COMMENT '性能比率',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_pv_system_month` (`pv_system_id`, `month`),
  KEY `idx_pv_system_id` (`pv_system_id`),
  CONSTRAINT `fk_pv_performance_baseline_pv_system_id` FOREIGN KEY (`pv_system_id`) REFERENCES `pv_system_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='光伏性能基準線表';

CREATE TABLE IF NOT EXISTS `pv_anomaly_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `pv_system_id` BIGINT NOT NULL COMMENT '光伏系統ID',
  `anomaly_type` VARCHAR(100) NOT NULL COMMENT '異常類型',
  `description` TEXT COMMENT '描述',
  `detected_value` DECIMAL(12,2) COMMENT '檢測到的值',
  `expected_value` DECIMAL(12,2) COMMENT '預期值',
  `detected_at` DATETIME NOT NULL COMMENT '檢測時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_pv_system_id` (`pv_system_id`),
  KEY `idx_detected_at` (`detected_at`),
  CONSTRAINT `fk_pv_anomaly_record_pv_system_id` FOREIGN KEY (`pv_system_id`) REFERENCES `pv_system_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='光伏異常記錄表';

CREATE TABLE IF NOT EXISTS `pv_fault_prediction_result` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `pv_system_id` BIGINT NOT NULL COMMENT '光伏系統ID',
  `fault_type` VARCHAR(100) NOT NULL COMMENT '故障類型',
  `probability` DECIMAL(5,2) NOT NULL COMMENT '故障概率(%)',
  `predicted_time` DATETIME COMMENT '預測故障時間',
  `recommendation` TEXT COMMENT '建議',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_pv_system_id` (`pv_system_id`),
  KEY `idx_predicted_time` (`predicted_time`),
  CONSTRAINT `fk_pv_fault_prediction_result_pv_system_id` FOREIGN KEY (`pv_system_id`) REFERENCES `pv_system_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='光伏故障預測結果表';

-- =====================================================
-- M5: 預測算法 (Forecasting Algorithm)
-- =====================================================

-- WI-5.1: 負荷預測 (Load Forecasting)

CREATE TABLE IF NOT EXISTS `forecast_model_version` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `model_name` VARCHAR(255) NOT NULL COMMENT '模型名稱',
  `model_type` ENUM('load','pv','weather','cold_start') NOT NULL COMMENT '模型類型',
  `version` VARCHAR(50) NOT NULL COMMENT '版本',
  `algorithm` VARCHAR(100) COMMENT '算法',
  `hyperparams_json` JSON COMMENT '超參數(JSON)',
  `accuracy_metric` DECIMAL(5,2) COMMENT '準確性指標',
  `model_file_url` VARCHAR(500) COMMENT '模型文件URL',
  `status` ENUM('training','active','archived') NOT NULL DEFAULT 'training' COMMENT '狀態',
  `trained_at` DATETIME COMMENT '訓練時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_model_name` (`model_name`),
  KEY `idx_model_type` (`model_type`),
  KEY `idx_status` (`status`),
  KEY `idx_version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='預測模型版本表';

CREATE TABLE IF NOT EXISTS `forecast_load_prediction` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `model_version_id` BIGINT NOT NULL COMMENT '模型版本ID',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `predict_time` DATETIME NOT NULL COMMENT '預測時間',
  `horizon` VARCHAR(50) NOT NULL COMMENT '預測範圍(15min/1hour/1day)',
  `predicted_value` DECIMAL(12,2) NOT NULL COMMENT '預測值(kW)',
  `actual_value` DECIMAL(12,2) COMMENT '實際值(kW)',
  `error_pct` DECIMAL(5,2) COMMENT '誤差百分比(%)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_model_version_id` (`model_version_id`),
  KEY `idx_site_id` (`site_id`),
  KEY `idx_predict_time` (`predict_time`),
  KEY `idx_horizon` (`horizon`),
  CONSTRAINT `fk_forecast_load_prediction_model_version_id` FOREIGN KEY (`model_version_id`) REFERENCES `forecast_model_version` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_forecast_load_prediction_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='負荷預測表';

CREATE TABLE IF NOT EXISTS `forecast_accuracy_metric` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `model_version_id` BIGINT NOT NULL COMMENT '模型版本ID',
  `metric_name` VARCHAR(100) NOT NULL COMMENT '指標名稱(MAE/RMSE/MAPE)',
  `metric_value` DECIMAL(10,4) NOT NULL COMMENT '指標值',
  `evaluation_period` VARCHAR(50) COMMENT '評估周期',
  `evaluated_at` DATETIME NOT NULL COMMENT '評估時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_model_version_id` (`model_version_id`),
  KEY `idx_metric_name` (`metric_name`),
  CONSTRAINT `fk_forecast_accuracy_metric_model_version_id` FOREIGN KEY (`model_version_id`) REFERENCES `forecast_model_version` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='預測準確度指標表';

-- WI-5.2: 光伏預測 (PV Forecasting)

CREATE TABLE IF NOT EXISTS `forecast_pv_prediction` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `model_version_id` BIGINT NOT NULL COMMENT '模型版本ID',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `predict_time` DATETIME NOT NULL COMMENT '預測時間',
  `horizon` VARCHAR(50) NOT NULL COMMENT '預測範圍(15min/1hour/1day)',
  `predicted_power_kw` DECIMAL(12,2) NOT NULL COMMENT '預測功率(kW)',
  `actual_power_kw` DECIMAL(12,2) COMMENT '實際功率(kW)',
  `error_pct` DECIMAL(5,2) COMMENT '誤差百分比(%)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_model_version_id` (`model_version_id`),
  KEY `idx_site_id` (`site_id`),
  KEY `idx_predict_time` (`predict_time`),
  KEY `idx_horizon` (`horizon`),
  CONSTRAINT `fk_forecast_pv_prediction_model_version_id` FOREIGN KEY (`model_version_id`) REFERENCES `forecast_model_version` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_forecast_pv_prediction_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='光伏發電功率預測表';

CREATE TABLE IF NOT EXISTS `weather_data` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `data_source` VARCHAR(100) COMMENT '數據源',
  `temperature` DECIMAL(5,2) COMMENT '溫度(°C)',
  `humidity` DECIMAL(5,2) COMMENT '濕度(%)',
  `irradiance` DECIMAL(10,2) COMMENT '輻照度(W/m²)',
  `wind_speed` DECIMAL(6,2) COMMENT '風速(m/s)',
  `cloud_cover` DECIMAL(5,2) COMMENT '雲量覆蓋(%)',
  `pressure` DECIMAL(7,2) COMMENT '氣壓(hPa)',
  `recorded_at` DATETIME NOT NULL COMMENT '記錄時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_recorded_at` (`recorded_at`),
  CONSTRAINT `fk_weather_data_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='氣象數據表';

CREATE TABLE IF NOT EXISTS `forecast_pv_model_param` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `model_version_id` BIGINT NOT NULL COMMENT '模型版本ID',
  `param_name` VARCHAR(100) NOT NULL COMMENT '參數名稱',
  `param_value` VARCHAR(500) COMMENT '參數值',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_model_version_id` (`model_version_id`),
  CONSTRAINT `fk_forecast_pv_model_param_model_version_id` FOREIGN KEY (`model_version_id`) REFERENCES `forecast_model_version` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='光伏預測模型參數表';

-- WI-5.3: 預測管理 (Forecast Management)

CREATE TABLE IF NOT EXISTS `forecast_result_history` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `model_type` VARCHAR(100) NOT NULL COMMENT '模型類型',
  `model_version_id` BIGINT NOT NULL COMMENT '模型版本ID',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `predict_date` DATE NOT NULL COMMENT '預測日期',
  `mape` DECIMAL(5,2) COMMENT '平均絕對百分比誤差(%)',
  `rmse` DECIMAL(10,2) COMMENT '均方根誤差',
  `r_squared` DECIMAL(5,4) COMMENT 'R²值',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_model_type` (`model_type`),
  KEY `idx_model_version_id` (`model_version_id`),
  KEY `idx_site_id` (`site_id`),
  KEY `idx_predict_date` (`predict_date`),
  CONSTRAINT `fk_forecast_result_history_model_version_id` FOREIGN KEY (`model_version_id`) REFERENCES `forecast_model_version` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_forecast_result_history_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='預測結果歷史表';

CREATE TABLE IF NOT EXISTS `forecast_metric_summary` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `model_type` VARCHAR(100) NOT NULL COMMENT '模型類型',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `period_type` VARCHAR(50) NOT NULL COMMENT '周期類型(daily/weekly/monthly)',
  `period_value` VARCHAR(50) NOT NULL COMMENT '周期值(例:2026-04)',
  `avg_mape` DECIMAL(5,2) COMMENT '平均MAPE(%)',
  `avg_rmse` DECIMAL(10,2) COMMENT '平均RMSE',
  `sample_count` INT COMMENT '樣本數',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_model_site_period` (`model_type`, `site_id`, `period_type`, `period_value`),
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_forecast_metric_summary_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='預測指標摘要表';

CREATE TABLE IF NOT EXISTS `forecast_model_comparison` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `model_a_id` BIGINT NOT NULL COMMENT '模型A版本ID',
  `model_b_id` BIGINT NOT NULL COMMENT '模型B版本ID',
  `comparison_metric` VARCHAR(100) COMMENT '比較指標',
  `model_a_value` DECIMAL(10,4) COMMENT '模型A值',
  `model_b_value` DECIMAL(10,4) COMMENT '模型B值',
  `winner` CHAR(1) COMMENT '勝者(A/B)',
  `compared_at` DATETIME NOT NULL COMMENT '比較時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_model_a_id` (`model_a_id`),
  KEY `idx_model_b_id` (`model_b_id`),
  CONSTRAINT `fk_forecast_model_comparison_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_forecast_model_comparison_model_a_id` FOREIGN KEY (`model_a_id`) REFERENCES `forecast_model_version` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_forecast_model_comparison_model_b_id` FOREIGN KEY (`model_b_id`) REFERENCES `forecast_model_version` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='預測模型比較表';

-- WI-5.4: 氣象 (Weather Data)

CREATE TABLE IF NOT EXISTS `weather_provider_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `provider_name` VARCHAR(255) NOT NULL COMMENT '提供商名稱',
  `api_url` VARCHAR(500) COMMENT 'API URL',
  `api_key_encrypted` VARCHAR(500) COMMENT '加密的API密鑰',
  `update_interval_min` INT NOT NULL DEFAULT 15 COMMENT '更新間隔(分鐘)',
  `enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否啟用(1=是,0=否)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_provider_name` (`provider_name`),
  KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='氣象提供商配置表';

CREATE TABLE IF NOT EXISTS `weather_current_data` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `provider_id` BIGINT NOT NULL COMMENT '提供商ID',
  `temperature` DECIMAL(5,2) COMMENT '溫度(°C)',
  `humidity` DECIMAL(5,2) COMMENT '濕度(%)',
  `irradiance` DECIMAL(10,2) COMMENT '輻照度(W/m²)',
  `wind_speed` DECIMAL(6,2) COMMENT '風速(m/s)',
  `wind_direction` DECIMAL(6,2) COMMENT '風向(度)',
  `cloud_cover` DECIMAL(5,2) COMMENT '雲量覆蓋(%)',
  `pressure` DECIMAL(7,2) COMMENT '氣壓(hPa)',
  `visibility` DECIMAL(6,2) COMMENT '能見度(km)',
  `recorded_at` DATETIME NOT NULL COMMENT '記錄時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_provider_id` (`provider_id`),
  KEY `idx_recorded_at` (`recorded_at`),
  CONSTRAINT `fk_weather_current_data_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_weather_current_data_provider_id` FOREIGN KEY (`provider_id`) REFERENCES `weather_provider_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='當前氣象數據表';

CREATE TABLE IF NOT EXISTS `weather_quality_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `provider_id` BIGINT NOT NULL COMMENT '提供商ID',
  `check_time` DATETIME NOT NULL COMMENT '檢查時間',
  `missing_fields` VARCHAR(500) COMMENT '缺失欄位',
  `quality_score` DECIMAL(5,2) COMMENT '質量評分',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_provider_id` (`provider_id`),
  KEY `idx_check_time` (`check_time`),
  CONSTRAINT `fk_weather_quality_log_provider_id` FOREIGN KEY (`provider_id`) REFERENCES `weather_provider_config` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='氣象數據質量日誌表';

-- WI-5.5: 冷啟動 (Cold Start)

CREATE TABLE IF NOT EXISTS `forecast_model_transfer_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `source_site_id` BIGINT NOT NULL COMMENT '源站點ID',
  `target_site_id` BIGINT NOT NULL COMMENT '目標站點ID',
  `model_version_id` BIGINT NOT NULL COMMENT '模型版本ID',
  `transfer_method` VARCHAR(100) COMMENT '遷移方法',
  `accuracy_before` DECIMAL(5,2) COMMENT '遷移前準確度(%)',
  `accuracy_after` DECIMAL(5,2) COMMENT '遷移後準確度(%)',
  `transferred_at` DATETIME NOT NULL COMMENT '遷移時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_source_site_id` (`source_site_id`),
  KEY `idx_target_site_id` (`target_site_id`),
  KEY `idx_model_version_id` (`model_version_id`),
  CONSTRAINT `fk_forecast_model_transfer_log_source_site_id` FOREIGN KEY (`source_site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_forecast_model_transfer_log_target_site_id` FOREIGN KEY (`target_site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_forecast_model_transfer_log_model_version_id` FOREIGN KEY (`model_version_id`) REFERENCES `forecast_model_version` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='預測模型遷移日誌表';

CREATE TABLE IF NOT EXISTS `cold_start_progress` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `phase` VARCHAR(50) COMMENT '階段名稱',
  `progress_pct` DECIMAL(5,2) COMMENT '進度百分比(%)',
  `data_days_collected` INT COMMENT '已收集數據天數',
  `min_days_required` INT COMMENT '所需最少天數',
  `status` VARCHAR(50) COMMENT '狀態',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_cold_start_progress_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='冷啟動進度表';

-- =====================================================
-- M6: 優化調度 (Optimization & Scheduling)
-- =====================================================

-- WI-6.1: 經濟調度 (Economic Dispatch)

CREATE TABLE IF NOT EXISTS `dispatch_plan_daily` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `plan_date` DATE NOT NULL COMMENT '計劃日期',
  `plan_type` ENUM('day_ahead','intraday') NOT NULL COMMENT '計劃類型',
  `objective_weights_json` JSON COMMENT '目標權重(JSON)',
  `solver_status` VARCHAR(50) COMMENT '求解器狀態',
  `cost_saving` DECIMAL(12,2) COMMENT '成本節省(元)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_site_plan_date_type` (`site_id`, `plan_date`, `plan_type`),
  KEY `idx_site_id` (`site_id`),
  KEY `idx_plan_date` (`plan_date`),
  CONSTRAINT `fk_dispatch_plan_daily_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日調度計劃表';

CREATE TABLE IF NOT EXISTS `dispatch_result_realtime` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `plan_id` BIGINT NOT NULL COMMENT '調度計劃ID',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `time_slot` DATETIME NOT NULL COMMENT '時間槽',
  `target_power_kw` DECIMAL(12,2) NOT NULL COMMENT '目標功率(kW)',
  `actual_power_kw` DECIMAL(12,2) COMMENT '實際功率(kW)',
  `executed_at` DATETIME COMMENT '執行時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_time_slot` (`time_slot`),
  CONSTRAINT `fk_dispatch_result_realtime_plan_id` FOREIGN KEY (`plan_id`) REFERENCES `dispatch_plan_daily` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_dispatch_result_realtime_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='實時調度結果表';

CREATE TABLE IF NOT EXISTS `dispatch_objective_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `objective_name` VARCHAR(255) NOT NULL COMMENT '目標名稱',
  `weight` DECIMAL(5,3) NOT NULL COMMENT '權重',
  `min_value` DECIMAL(12,2) COMMENT '最小值',
  `max_value` DECIMAL(12,2) COMMENT '最大值',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_site_objective` (`site_id`, `objective_name`),
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_dispatch_objective_config_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='調度目標配置表';

CREATE TABLE IF NOT EXISTS `dispatch_constraint_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `plan_id` BIGINT NOT NULL COMMENT '調度計劃ID',
  `constraint_name` VARCHAR(255) NOT NULL COMMENT '約束名稱',
  `violation_value` DECIMAL(12,2) COMMENT '違反值',
  `limit_value` DECIMAL(12,2) COMMENT '限制值',
  `logged_at` DATETIME NOT NULL COMMENT '記錄時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_logged_at` (`logged_at`),
  CONSTRAINT `fk_dispatch_constraint_log_plan_id` FOREIGN KEY (`plan_id`) REFERENCES `dispatch_plan_daily` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='調度約束日誌表';

-- WI-6.2: 有序充電 (Ordered EV Charging)

CREATE TABLE IF NOT EXISTS `ev_charger_info` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `charger_name` VARCHAR(255) NOT NULL COMMENT '充電器名稱',
  `charger_code` VARCHAR(100) NOT NULL UNIQUE COMMENT '充電器代碼',
  `charger_type` ENUM('AC','DC','AC_DC') NOT NULL COMMENT '充電器類型',
  `max_power_kw` DECIMAL(12,2) NOT NULL COMMENT '最大功率(kW)',
  `connector_type` VARCHAR(100) COMMENT '連接器類型',
  `location` VARCHAR(255) COMMENT '位置',
  `status` VARCHAR(50) COMMENT '狀態',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_charger_code` (`charger_code`),
  CONSTRAINT `fk_ev_charger_info_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電動車充電器信息表';

CREATE TABLE IF NOT EXISTS `ev_charger_status` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `charger_id` BIGINT NOT NULL COMMENT '充電器ID',
  `state` ENUM('idle','charging','faulted','offline') NOT NULL COMMENT '狀態',
  `current_power_kw` DECIMAL(12,2) COMMENT '當前功率(kW)',
  `energy_delivered_kwh` DECIMAL(14,2) COMMENT '已交付能量(kWh)',
  `connected_vehicle_id` VARCHAR(100) COMMENT '連接車輛ID',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  KEY `idx_charger_id` (`charger_id`),
  KEY `idx_state` (`state`),
  KEY `idx_updated_at` (`updated_at`),
  CONSTRAINT `fk_ev_charger_status_charger_id` FOREIGN KEY (`charger_id`) REFERENCES `ev_charger_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電動車充電器狀態表';

CREATE TABLE IF NOT EXISTS `ev_session` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `charger_id` BIGINT NOT NULL COMMENT '充電器ID',
  `vehicle_id` VARCHAR(100) NOT NULL COMMENT '車輛ID',
  `start_time` DATETIME NOT NULL COMMENT '開始時間',
  `end_time` DATETIME COMMENT '結束時間',
  `energy_kwh` DECIMAL(14,2) COMMENT '充電能量(kWh)',
  `max_power_kw` DECIMAL(12,2) COMMENT '最大功率(kW)',
  `cost` DECIMAL(12,2) COMMENT '成本(元)',
  `status` VARCHAR(50) COMMENT '狀態',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_charger_id` (`charger_id`),
  KEY `idx_vehicle_id` (`vehicle_id`),
  KEY `idx_start_time` (`start_time`),
  CONSTRAINT `fk_ev_session_charger_id` FOREIGN KEY (`charger_id`) REFERENCES `ev_charger_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電動車充電會話表';

CREATE TABLE IF NOT EXISTS `ev_power_control_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `charger_id` BIGINT NOT NULL COMMENT '充電器ID',
  `session_id` BIGINT NOT NULL COMMENT '充電會話ID',
  `target_power_kw` DECIMAL(12,2) NOT NULL COMMENT '目標功率(kW)',
  `actual_power_kw` DECIMAL(12,2) COMMENT '實際功率(kW)',
  `reason` VARCHAR(255) COMMENT '控制原因',
  `controlled_at` DATETIME NOT NULL COMMENT '控制時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_charger_id` (`charger_id`),
  KEY `idx_session_id` (`session_id`),
  KEY `idx_controlled_at` (`controlled_at`),
  CONSTRAINT `fk_ev_power_control_log_charger_id` FOREIGN KEY (`charger_id`) REFERENCES `ev_charger_info` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ev_power_control_log_session_id` FOREIGN KEY (`session_id`) REFERENCES `ev_session` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電動車功率控制日誌表';

-- WI-6.3: 柔性負荷 (Flexible Load)

CREATE TABLE IF NOT EXISTS `flexible_load_device` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `device_name` VARCHAR(255) NOT NULL COMMENT '設備名稱',
  `device_type` VARCHAR(100) COMMENT '設備類型',
  `rated_power_kw` DECIMAL(12,2) NOT NULL COMMENT '額定功率(kW)',
  `min_power_kw` DECIMAL(12,2) COMMENT '最小功率(kW)',
  `max_power_kw` DECIMAL(12,2) COMMENT '最大功率(kW)',
  `ramp_rate` DECIMAL(12,4) COMMENT '斜率(kW/分鐘)',
  `priority` INT COMMENT '優先級',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_device_type` (`device_type`),
  CONSTRAINT `fk_flexible_load_device_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='柔性負荷設備表';

CREATE TABLE IF NOT EXISTS `flexible_load_status` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `current_power_kw` DECIMAL(12,2) COMMENT '當前功率(kW)',
  `setpoint_kw` DECIMAL(12,2) COMMENT '設定點(kW)',
  `mode` VARCHAR(50) COMMENT '模式',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  KEY `idx_device_id` (`device_id`),
  KEY `idx_updated_at` (`updated_at`),
  CONSTRAINT `fk_flexible_load_status_device_id` FOREIGN KEY (`device_id`) REFERENCES `flexible_load_device` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='柔性負荷狀態表';

CREATE TABLE IF NOT EXISTS `ac_comfort_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `temp_min` DECIMAL(5,2) COMMENT '最小溫度(°C)',
  `temp_max` DECIMAL(5,2) COMMENT '最大溫度(°C)',
  `humidity_min` DECIMAL(5,2) COMMENT '最小濕度(%)',
  `humidity_max` DECIMAL(5,2) COMMENT '最大濕度(%)',
  `priority` INT COMMENT '優先級',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_device_id` (`device_id`),
  CONSTRAINT `fk_ac_comfort_config_device_id` FOREIGN KEY (`device_id`) REFERENCES `flexible_load_device` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='空調舒適度配置表';

CREATE TABLE IF NOT EXISTS `flexible_load_control_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `command_type` VARCHAR(100) COMMENT '命令類型',
  `before_power_kw` DECIMAL(12,2) COMMENT '控制前功率(kW)',
  `after_power_kw` DECIMAL(12,2) COMMENT '控制後功率(kW)',
  `reason` VARCHAR(255) COMMENT '控制原因',
  `controlled_at` DATETIME NOT NULL COMMENT '控制時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_device_id` (`device_id`),
  KEY `idx_controlled_at` (`controlled_at`),
  CONSTRAINT `fk_flexible_load_control_log_device_id` FOREIGN KEY (`device_id`) REFERENCES `flexible_load_device` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='柔性負荷控制日誌表';

-- WI-6.4: 功率聚合 (Power Aggregation)

CREATE TABLE IF NOT EXISTS `aggregation_power_snapshot` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `total_generation_kw` DECIMAL(12,2) COMMENT '總發電功率(kW)',
  `total_load_kw` DECIMAL(12,2) COMMENT '總負荷功率(kW)',
  `total_storage_kw` DECIMAL(12,2) COMMENT '儲能功率(kW)',
  `total_ev_kw` DECIMAL(12,2) COMMENT '電動車充電功率(kW)',
  `net_power_kw` DECIMAL(12,2) COMMENT '淨功率(kW)',
  `snapshot_time` DATETIME NOT NULL COMMENT '快照時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_snapshot_time` (`snapshot_time`),
  CONSTRAINT `fk_aggregation_power_snapshot_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='功率聚合快照表';

CREATE TABLE IF NOT EXISTS `aggregation_decompose_result` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `snapshot_id` BIGINT NOT NULL COMMENT '快照ID',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `allocated_power_kw` DECIMAL(12,2) NOT NULL COMMENT '分配功率(kW)',
  `priority` INT COMMENT '優先級',
  `decomposed_at` DATETIME NOT NULL COMMENT '分解時間',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_snapshot_id` (`snapshot_id`),
  KEY `idx_device_id` (`device_id`),
  CONSTRAINT `fk_aggregation_decompose_result_snapshot_id` FOREIGN KEY (`snapshot_id`) REFERENCES `aggregation_power_snapshot` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_aggregation_decompose_result_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='功率分解結果表';

CREATE TABLE IF NOT EXISTS `aggregation_device_priority` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `device_id` BIGINT NOT NULL COMMENT '設備ID',
  `priority_level` INT NOT NULL COMMENT '優先級別',
  `min_power_kw` DECIMAL(12,2) COMMENT '最小功率(kW)',
  `max_power_kw` DECIMAL(12,2) COMMENT '最大功率(kW)',
  `ramp_up_rate` DECIMAL(12,4) COMMENT '上升斜率(kW/分鐘)',
  `ramp_down_rate` DECIMAL(12,4) COMMENT '下降斜率(kW/分鐘)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_site_device` (`site_id`, `device_id`),
  KEY `idx_site_id` (`site_id`),
  KEY `idx_device_id` (`device_id`),
  CONSTRAINT `fk_aggregation_device_priority_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_aggregation_device_priority_device_id` FOREIGN KEY (`device_id`) REFERENCES `device_info` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聚合設備優先級表';

-- WI-6.5: 電價 (Pricing & Cost Management)

CREATE TABLE IF NOT EXISTS `pricing_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `pricing_name` VARCHAR(255) NOT NULL COMMENT '電價計劃名稱',
  `period_type` ENUM('sharp','peak','flat','valley') NOT NULL COMMENT '時段類型',
  `start_time` TIME NOT NULL COMMENT '開始時間',
  `end_time` TIME NOT NULL COMMENT '結束時間',
  `buy_price` DECIMAL(10,4) NOT NULL COMMENT '購電價格(元/kWh)',
  `sell_price` DECIMAL(10,4) NOT NULL COMMENT '售電價格(元/kWh)',
  `effective_date` DATE NOT NULL COMMENT '生效日期',
  `expire_date` DATE COMMENT '過期日期',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_period_type` (`period_type`),
  KEY `idx_effective_date` (`effective_date`),
  CONSTRAINT `fk_pricing_config_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電價配置表';

CREATE TABLE IF NOT EXISTS `pricing_cost_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `stat_date` DATE NOT NULL COMMENT '統計日期',
  `period_type` VARCHAR(50) NOT NULL COMMENT '時段類型',
  `energy_kwh` DECIMAL(14,2) NOT NULL COMMENT '能量(kWh)',
  `cost_amount` DECIMAL(12,2) NOT NULL COMMENT '成本金額(元)',
  `direction` ENUM('buy','sell') NOT NULL COMMENT '方向：buy(購電),sell(售電)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_site_date_period_direction` (`site_id`, `stat_date`, `period_type`, `direction`),
  KEY `idx_site_id` (`site_id`),
  KEY `idx_stat_date` (`stat_date`),
  CONSTRAINT `fk_pricing_cost_log_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電價成本日誌表';

CREATE TABLE IF NOT EXISTS `pricing_revenue_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `revenue_type` ENUM('peak_shaving','demand_response','pv_sell','vpp') NOT NULL COMMENT '收益類型',
  `amount` DECIMAL(12,2) NOT NULL COMMENT '金額(元)',
  `stat_date` DATE NOT NULL COMMENT '統計日期',
  `description` VARCHAR(500) COMMENT '描述',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_revenue_type` (`revenue_type`),
  KEY `idx_stat_date` (`stat_date`),
  CONSTRAINT `fk_pricing_revenue_record_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電價收益記錄表';

CREATE TABLE IF NOT EXISTS `pricing_monthly_report` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `year_month` VARCHAR(7) NOT NULL COMMENT '統計年月(YYYY-MM)',
  `total_cost` DECIMAL(14,2) COMMENT '總成本(元)',
  `total_revenue` DECIMAL(14,2) COMMENT '總收益(元)',
  `net_saving` DECIMAL(14,2) COMMENT '淨節省(元)',
  `peak_saving` DECIMAL(14,2) COMMENT '削峰節省(元)',
  `report_file_url` VARCHAR(500) COMMENT '報告文件URL',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_site_year_month` (`site_id`, `year_month`),
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_pricing_monthly_report_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電價月度報告表';

-- WI-6.6: 碳排 (Carbon Emissions)

CREATE TABLE IF NOT EXISTS `carbon_emission_factor` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `factor_name` VARCHAR(255) NOT NULL COMMENT '因子名稱',
  `factor_code` VARCHAR(100) NOT NULL UNIQUE COMMENT '因子代碼',
  `region` VARCHAR(100) COMMENT '地區',
  `value` DECIMAL(12,6) NOT NULL COMMENT '因子值',
  `unit` VARCHAR(50) COMMENT '單位(kgCO2/kWh)',
  `source_standard` VARCHAR(255) COMMENT '來源標準',
  `effective_year` SMALLINT COMMENT '生效年份',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_factor_code` (`factor_code`),
  KEY `idx_region` (`region`),
  KEY `idx_effective_year` (`effective_year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='碳排放因子表';

CREATE TABLE IF NOT EXISTS `carbon_emission_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `emission_source` VARCHAR(100) NOT NULL COMMENT '排放源',
  `energy_kwh` DECIMAL(14,2) NOT NULL COMMENT '能量(kWh)',
  `emission_factor_id` BIGINT NOT NULL COMMENT '排放因子ID',
  `emission_kg_co2` DECIMAL(14,2) NOT NULL COMMENT '排放量(kgCO2)',
  `logged_date` DATE NOT NULL COMMENT '記錄日期',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_emission_factor_id` (`emission_factor_id`),
  KEY `idx_logged_date` (`logged_date`),
  CONSTRAINT `fk_carbon_emission_log_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_carbon_emission_log_emission_factor_id` FOREIGN KEY (`emission_factor_id`) REFERENCES `carbon_emission_factor` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='碳排放日誌表';

CREATE TABLE IF NOT EXISTS `carbon_baseline_config` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `baseline_year` SMALLINT NOT NULL COMMENT '基準年份',
  `baseline_emission_kg` DECIMAL(14,2) NOT NULL COMMENT '基準排放量(kgCO2)',
  `methodology` VARCHAR(255) COMMENT '方法論',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_site_year` (`site_id`, `baseline_year`),
  KEY `idx_site_id` (`site_id`),
  CONSTRAINT `fk_carbon_baseline_config_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='碳排放基準配置表';

CREATE TABLE IF NOT EXISTS `carbon_reduction_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `reduction_type` VARCHAR(100) NOT NULL COMMENT '減排類型',
  `reduction_kg_co2` DECIMAL(14,2) NOT NULL COMMENT '減排量(kgCO2)',
  `evidence` TEXT COMMENT '證據',
  `recorded_date` DATE NOT NULL COMMENT '記錄日期',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_site_id` (`site_id`),
  KEY `idx_reduction_type` (`reduction_type`),
  KEY `idx_recorded_date` (`recorded_date`),
  CONSTRAINT `fk_carbon_reduction_record_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='碳減排記錄表';

-- WI-6.7: 策略 (Strategy Management)

CREATE TABLE IF NOT EXISTS `strategy_version` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `strategy_id` BIGINT NOT NULL COMMENT '策略ID',
  `version_no` INT NOT NULL COMMENT '版本號',
  `config_json` JSON COMMENT '配置(JSON)',
  `change_note` TEXT COMMENT '變更說明',
  `created_by` BIGINT NOT NULL COMMENT '創建者ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  UNIQUE KEY `uniq_strategy_version` (`strategy_id`, `version_no`),
  KEY `idx_strategy_id` (`strategy_id`),
  KEY `idx_created_by` (`created_by`),
  CONSTRAINT `fk_strategy_version_strategy_id` FOREIGN KEY (`strategy_id`) REFERENCES `strategy_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_strategy_version_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='策略版本表';

CREATE TABLE IF NOT EXISTS `strategy_active_record` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `strategy_id` BIGINT NOT NULL COMMENT '策略ID',
  `version_id` BIGINT NOT NULL COMMENT '策略版本ID',
  `site_id` BIGINT NOT NULL COMMENT '站點ID',
  `activated_at` DATETIME NOT NULL COMMENT '激活時間',
  `deactivated_at` DATETIME COMMENT '停用時間',
  `status` ENUM('active','inactive') NOT NULL DEFAULT 'active' COMMENT '狀態',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_strategy_id` (`strategy_id`),
  KEY `idx_version_id` (`version_id`),
  KEY `idx_site_id` (`site_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_strategy_active_record_strategy_id` FOREIGN KEY (`strategy_id`) REFERENCES `strategy_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_strategy_active_record_version_id` FOREIGN KEY (`version_id`) REFERENCES `strategy_version` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_strategy_active_record_site_id` FOREIGN KEY (`site_id`) REFERENCES `site_metadata` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='策略激活記錄表';

CREATE TABLE IF NOT EXISTS `strategy_evaluation_result` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主鍵',
  `strategy_id` BIGINT NOT NULL COMMENT '策略ID',
  `evaluation_period` VARCHAR(50) NOT NULL COMMENT '評估周期',
  `kpi_name` VARCHAR(255) NOT NULL COMMENT 'KPI名稱',
  `kpi_value` DECIMAL(12,2) NOT NULL COMMENT 'KPI值',
  `target_value` DECIMAL(12,2) COMMENT '目標值',
  `pass` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否通過(1=是,0=否)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  KEY `idx_strategy_id` (`strategy_id`),
  KEY `idx_evaluation_period` (`evaluation_period`),
  KEY `idx_pass` (`pass`),
  CONSTRAINT `fk_strategy_evaluation_result_strategy_id` FOREIGN KEY (`strategy_id`) REFERENCES `strategy_definition` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='策略評估結果表';

-- =====================================================
-- End of EMS Schema Supplement
-- =====================================================

-- ============================================================================
-- Part 4-6: M7 VPP管理 / M8 智能運維 / M9 建築能碳 / M10 整合測試
-- ============================================================================

-- =====================================================
-- EMS 數據庫架構 Part 4-6: M7-M10 表定義
-- MySQL 8.0 InnoDB UTF8mb4
-- =====================================================

-- =====================================================
-- M7: VPP 子站管理 (6 work items)
-- =====================================================

-- WI-7.1 資源總覽

CREATE TABLE IF NOT EXISTS vpp_resource_type (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '虛擬電廠資源類型ID',
  type_name VARCHAR(64) NOT NULL COMMENT '資源類型名稱',
  type_code VARCHAR(32) NOT NULL UNIQUE COMMENT '資源類型代碼',
  description TEXT COMMENT '類型描述',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_type_code (type_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠資源類型表';

CREATE TABLE IF NOT EXISTS vpp_resource (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '虛擬電廠資源ID',
  resource_type_id BIGINT NOT NULL COMMENT '資源類型ID',
  resource_name VARCHAR(128) NOT NULL COMMENT '資源名稱',
  resource_code VARCHAR(64) NOT NULL UNIQUE COMMENT '資源代碼',
  site_id BIGINT COMMENT '站點ID',
  enterprise_id BIGINT COMMENT '企業ID',
  installed_capacity_kw DECIMAL(15, 2) COMMENT '額定容量(kW)',
  adjustable_capacity_kw DECIMAL(15, 2) COMMENT '可調容量(kW)',
  status VARCHAR(32) COMMENT '資源狀態',
  commissioned_at DATETIME COMMENT '投運時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (resource_type_id) REFERENCES vpp_resource_type(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site_metadata(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_resource_code (resource_code),
  INDEX idx_site_id (site_id),
  INDEX idx_enterprise_id (enterprise_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠資源表';

CREATE TABLE IF NOT EXISTS vpp_potential (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '潛力評估記錄ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  assessment_date DATE NOT NULL COMMENT '評估日期',
  max_up_kw DECIMAL(15, 2) COMMENT '最大上調容量(kW)',
  max_down_kw DECIMAL(15, 2) COMMENT '最大下調容量(kW)',
  available_hours INT COMMENT '可用時長(小時)',
  confidence_score DECIMAL(5, 2) COMMENT '置信度評分(0-100)',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_resource_id (resource_id),
  INDEX idx_assessment_date (assessment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠資源潛力評估表';

CREATE TABLE IF NOT EXISTS vpp_stats_daily (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '日統計記錄ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  stat_date DATE NOT NULL COMMENT '統計日期',
  dispatched_energy_kwh DECIMAL(15, 2) COMMENT '調度能量(kWh)',
  response_count INT COMMENT '響應次數',
  avg_response_time_sec INT COMMENT '平均響應時間(秒)',
  revenue DECIMAL(15, 2) COMMENT '收益(元)',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uk_resource_stat_date (resource_id, stat_date),
  INDEX idx_stat_date (stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠資源日統計表';

-- WI-7.2 資源檔案

CREATE TABLE IF NOT EXISTS vpp_enterprise_archive (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '企業檔案ID',
  enterprise_name VARCHAR(128) NOT NULL COMMENT '企業名稱',
  enterprise_code VARCHAR(64) NOT NULL UNIQUE COMMENT '企業代碼',
  contact_person VARCHAR(64) COMMENT '聯繫人',
  contact_phone VARCHAR(20) COMMENT '聯繫電話',
  address VARCHAR(256) COMMENT '企業地址',
  business_license VARCHAR(128) COMMENT '營業執照號',
  status VARCHAR(32) COMMENT '企業狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_enterprise_code (enterprise_code),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠企業檔案表';

CREATE TABLE IF NOT EXISTS vpp_resource_archive (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '資源檔案ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  enterprise_id BIGINT NOT NULL COMMENT '企業ID',
  technical_params_json JSON COMMENT '技術參數JSON',
  maintenance_schedule TEXT COMMENT '維保計劃',
  warranty_expire DATE COMMENT '保修期截止',
  documents_json JSON COMMENT '相關文件JSON',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (enterprise_id) REFERENCES vpp_enterprise_archive(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  UNIQUE KEY uk_resource_id (resource_id),
  INDEX idx_enterprise_id (enterprise_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠資源檔案表';

CREATE TABLE IF NOT EXISTS vpp_contract (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '合同ID',
  enterprise_id BIGINT NOT NULL COMMENT '企業ID',
  contract_no VARCHAR(64) NOT NULL UNIQUE COMMENT '合同號',
  contract_type VARCHAR(32) COMMENT '合同類型',
  start_date DATE NOT NULL COMMENT '合同開始日期',
  end_date DATE NOT NULL COMMENT '合同結束日期',
  capacity_kw DECIMAL(15, 2) COMMENT '合同容量(kW)',
  price_per_kwh DECIMAL(10, 4) COMMENT '單位電價(元/kWh)',
  penalty_rate DECIMAL(5, 2) COMMENT '違約金比率(%)',
  status VARCHAR(32) COMMENT '合同狀態',
  signed_at DATETIME COMMENT '簽署時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (enterprise_id) REFERENCES vpp_enterprise_archive(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_contract_no (contract_no),
  INDEX idx_status (status),
  INDEX idx_start_date (start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠合同表';

CREATE TABLE IF NOT EXISTS vpp_archive_history (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '檔案修改歷史ID',
  entity_type VARCHAR(64) NOT NULL COMMENT '實體類型',
  entity_id BIGINT NOT NULL COMMENT '實體ID',
  field_name VARCHAR(128) NOT NULL COMMENT '字段名',
  old_value TEXT COMMENT '舊值',
  new_value TEXT COMMENT '新值',
  changed_by BIGINT COMMENT '修改人ID',
  changed_at DATETIME NOT NULL COMMENT '修改時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (changed_by) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_entity_type_id (entity_type, entity_id),
  INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠檔案修改歷史表';

-- WI-7.3 資源聚合

CREATE TABLE IF NOT EXISTS vpp_aggregation_scheme (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '聚合方案ID',
  scheme_name VARCHAR(128) NOT NULL COMMENT '方案名稱',
  target_capacity_kw DECIMAL(15, 2) COMMENT '目標容量(kW)',
  resource_selection_criteria_json JSON COMMENT '資源選擇條件JSON',
  priority_weights_json JSON COMMENT '優先級權重JSON',
  status VARCHAR(32) COMMENT '方案狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠資源聚合方案表';

CREATE TABLE IF NOT EXISTS vpp_aggregation_result (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '聚合結果ID',
  scheme_id BIGINT NOT NULL COMMENT '聚合方案ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  allocated_capacity_kw DECIMAL(15, 2) COMMENT '分配容量(kW)',
  priority_rank INT COMMENT '優先級排名',
  analyzed_at DATETIME COMMENT '分析時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (scheme_id) REFERENCES vpp_aggregation_scheme(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uk_scheme_resource (scheme_id, resource_id),
  INDEX idx_analyzed_at (analyzed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠資源聚合結果表';

CREATE TABLE IF NOT EXISTS vpp_potential_forecast (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '潛力預測ID',
  scheme_id BIGINT NOT NULL COMMENT '聚合方案ID',
  forecast_time DATETIME NOT NULL COMMENT '預測時刻',
  up_capacity_kw DECIMAL(15, 2) COMMENT '上調潛力(kW)',
  down_capacity_kw DECIMAL(15, 2) COMMENT '下調潛力(kW)',
  confidence DECIMAL(5, 2) COMMENT '置信度(0-100)',
  forecasted_at DATETIME COMMENT '預測生成時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (scheme_id) REFERENCES vpp_aggregation_scheme(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_scheme_id (scheme_id),
  INDEX idx_forecast_time (forecast_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠潛力預測表';

-- WI-7.4 協同調控

CREATE TABLE IF NOT EXISTS vpp_dispatch_command (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '調度命令ID',
  command_source VARCHAR(64) COMMENT '命令來源',
  command_type VARCHAR(32) COMMENT '命令類型',
  target_power_kw DECIMAL(15, 2) COMMENT '目標功率(kW)',
  start_time DATETIME NOT NULL COMMENT '開始時間',
  end_time DATETIME NOT NULL COMMENT '結束時間',
  priority INT COMMENT '優先級',
  status VARCHAR(32) COMMENT '命令狀態',
  received_at DATETIME COMMENT '接收時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_status (status),
  INDEX idx_start_time (start_time),
  INDEX idx_received_at (received_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠調度命令表';

CREATE TABLE IF NOT EXISTS vpp_dispatch_plan (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '調度計劃ID',
  command_id BIGINT NOT NULL COMMENT '調度命令ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  allocated_power_kw DECIMAL(15, 2) COMMENT '分配功率(kW)',
  start_time DATETIME NOT NULL COMMENT '開始時間',
  end_time DATETIME NOT NULL COMMENT '結束時間',
  status VARCHAR(32) COMMENT '計劃狀態',
  sent_at DATETIME COMMENT '發送時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (command_id) REFERENCES vpp_dispatch_command(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_command_id (command_id),
  INDEX idx_resource_id (resource_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠調度計劃表';

CREATE TABLE IF NOT EXISTS vpp_power_curve (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '功率曲線ID',
  command_id BIGINT NOT NULL COMMENT '調度命令ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  time_point DATETIME NOT NULL COMMENT '時間點',
  target_kw DECIMAL(15, 2) COMMENT '目標功率(kW)',
  actual_kw DECIMAL(15, 2) COMMENT '實際功率(kW)',
  deviation_kw DECIMAL(15, 2) COMMENT '偏差(kW)',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (command_id) REFERENCES vpp_dispatch_command(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_command_id (command_id),
  INDEX idx_resource_id (resource_id),
  INDEX idx_time_point (time_point)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠功率曲線表';

CREATE TABLE IF NOT EXISTS vpp_deviation_log (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '偏差日誌ID',
  command_id BIGINT NOT NULL COMMENT '調度命令ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  deviation_kw DECIMAL(15, 2) COMMENT '偏差值(kW)',
  deviation_pct DECIMAL(5, 2) COMMENT '偏差比率(%)',
  cause VARCHAR(256) COMMENT '偏差原因',
  logged_at DATETIME COMMENT '記錄時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (command_id) REFERENCES vpp_dispatch_command(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_command_id (command_id),
  INDEX idx_logged_at (logged_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠偏差日誌表';

CREATE TABLE IF NOT EXISTS vpp_alert (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '虛擬電廠告警ID',
  related_entity_type VARCHAR(64) COMMENT '關聯實體類型',
  related_entity_id BIGINT COMMENT '關聯實體ID',
  alert_type VARCHAR(64) COMMENT '告警類型',
  severity VARCHAR(32) COMMENT '嚴重級別',
  message TEXT COMMENT '告警信息',
  status VARCHAR(32) COMMENT '告警狀態',
  triggered_at DATETIME COMMENT '觸發時間',
  resolved_at DATETIME COMMENT '解決時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_status (status),
  INDEX idx_triggered_at (triggered_at),
  INDEX idx_entity_type_id (related_entity_type, related_entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠告警表';

-- WI-7.5 響應評估與結算

CREATE TABLE IF NOT EXISTS vpp_settlement_record (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '結算記錄ID',
  command_id BIGINT NOT NULL COMMENT '調度命令ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  settlement_period VARCHAR(32) COMMENT '結算周期',
  energy_kwh DECIMAL(15, 2) COMMENT '能量(kWh)',
  price_per_kwh DECIMAL(10, 4) COMMENT '單位電價(元/kWh)',
  amount DECIMAL(15, 2) COMMENT '應付金額(元)',
  penalty_amount DECIMAL(15, 2) COMMENT '罰款金額(元)',
  net_amount DECIMAL(15, 2) COMMENT '淨金額(元)',
  status VARCHAR(32) COMMENT '結算狀態',
  settled_at DATETIME COMMENT '結算時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (command_id) REFERENCES vpp_dispatch_command(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_status (status),
  INDEX idx_settled_at (settled_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠結算記錄表';

CREATE TABLE IF NOT EXISTS vpp_revenue_analysis (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '收益分析ID',
  resource_id BIGINT NOT NULL COMMENT '資源ID',
  year_month VARCHAR(7) NOT NULL COMMENT '年月(YYYY-MM)',
  total_revenue DECIMAL(15, 2) COMMENT '總收益(元)',
  penalty_total DECIMAL(15, 2) COMMENT '總罰款(元)',
  net_revenue DECIMAL(15, 2) COMMENT '淨收益(元)',
  roi_pct DECIMAL(5, 2) COMMENT '投資回報率(%)',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (resource_id) REFERENCES vpp_resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uk_resource_month (resource_id, year_month),
  INDEX idx_year_month (year_month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠收益分析表';

CREATE TABLE IF NOT EXISTS vpp_invoice (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '發票ID',
  enterprise_id BIGINT NOT NULL COMMENT '企業ID',
  invoice_no VARCHAR(64) NOT NULL UNIQUE COMMENT '發票號碼',
  amount DECIMAL(15, 2) COMMENT '金額(元)',
  tax_amount DECIMAL(15, 2) COMMENT '稅額(元)',
  total_amount DECIMAL(15, 2) COMMENT '合計金額(元)',
  status VARCHAR(32) COMMENT '發票狀態',
  issued_at DATETIME COMMENT '開票時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (enterprise_id) REFERENCES vpp_enterprise_archive(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_invoice_no (invoice_no),
  INDEX idx_status (status),
  INDEX idx_issued_at (issued_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠發票表';

-- WI-7.6 電力交易

CREATE TABLE IF NOT EXISTS vpp_trading_analysis (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '交易分析ID',
  analysis_type VARCHAR(64) COMMENT '分析類型',
  analysis_date DATE NOT NULL COMMENT '分析日期',
  market_price DECIMAL(10, 4) COMMENT '市場電價(元/kWh)',
  predicted_price DECIMAL(10, 4) COMMENT '預測電價(元/kWh)',
  spread DECIMAL(10, 4) COMMENT '價差(元/kWh)',
  recommendation VARCHAR(64) COMMENT '推薦策略',
  confidence DECIMAL(5, 2) COMMENT '置信度(0-100)',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_analysis_date (analysis_date),
  INDEX idx_analysis_type (analysis_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠交易分析表';

CREATE TABLE IF NOT EXISTS vpp_arbitrage_history (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '套利歷史ID',
  trade_date DATE NOT NULL COMMENT '交易日期',
  buy_period VARCHAR(32) COMMENT '購買時段',
  sell_period VARCHAR(32) COMMENT '售賣時段',
  buy_price DECIMAL(10, 4) COMMENT '購買電價(元/kWh)',
  sell_price DECIMAL(10, 4) COMMENT '售賣電價(元/kWh)',
  energy_kwh DECIMAL(15, 2) COMMENT '能量(kWh)',
  profit DECIMAL(15, 2) COMMENT '利潤(元)',
  status VARCHAR(32) COMMENT '交易狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_trade_date (trade_date),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠套利歷史表';

CREATE TABLE IF NOT EXISTS vpp_forecast_result (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '預測結果ID',
  forecast_type VARCHAR(64) COMMENT '預測類型',
  site_id BIGINT COMMENT '站點ID',
  forecast_time DATETIME NOT NULL COMMENT '預測時刻',
  value DECIMAL(15, 2) COMMENT '預測值',
  confidence DECIMAL(5, 2) COMMENT '置信度(0-100)',
  model_version VARCHAR(32) COMMENT '模型版本',
  forecasted_at DATETIME COMMENT '預測生成時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (site_id) REFERENCES site_metadata(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_forecast_type (forecast_type),
  INDEX idx_forecast_time (forecast_time),
  INDEX idx_site_id (site_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='虛擬電廠預測結果表';

-- =====================================================
-- M8: 智能運維 (5 work items)
-- =====================================================

-- WI-8.1 設備狀態AI監測

CREATE TABLE IF NOT EXISTS ops_device_status (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '設備狀態記錄ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  metric_name VARCHAR(128) NOT NULL COMMENT '指標名稱',
  metric_value DECIMAL(15, 2) COMMENT '指標值',
  health_score DECIMAL(5, 2) COMMENT '健康度評分(0-100)',
  status VARCHAR(32) COMMENT '狀態',
  monitored_at DATETIME NOT NULL COMMENT '監測時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_metric_name (metric_name),
  INDEX idx_monitored_at (monitored_at),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備狀態監測表';

CREATE TABLE IF NOT EXISTS ops_anomaly_record (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '異常記錄ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  anomaly_type VARCHAR(64) COMMENT '異常類型',
  metric_name VARCHAR(128) COMMENT '指標名稱',
  expected_value DECIMAL(15, 2) COMMENT '期望值',
  actual_value DECIMAL(15, 2) COMMENT '實際值',
  severity VARCHAR(32) COMMENT '嚴重級別',
  description TEXT COMMENT '異常描述',
  status VARCHAR(32) COMMENT '異常狀態',
  detected_at DATETIME COMMENT '檢測時間',
  resolved_at DATETIME COMMENT '解決時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_detected_at (detected_at),
  INDEX idx_status (status),
  INDEX idx_severity (severity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備異常記錄表';

CREATE TABLE IF NOT EXISTS ops_diagnosis_result (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '診斷結果ID',
  anomaly_id BIGINT NOT NULL COMMENT '異常記錄ID',
  diagnosis_model VARCHAR(128) COMMENT '診斷模型',
  root_cause TEXT COMMENT '根本原因',
  confidence DECIMAL(5, 2) COMMENT '置信度(0-100)',
  recommendation TEXT COMMENT '推薦措施',
  diagnosed_at DATETIME COMMENT '診斷時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (anomaly_id) REFERENCES ops_anomaly_record(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_anomaly_id (anomaly_id),
  INDEX idx_diagnosed_at (diagnosed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='設備診斷結果表';

-- WI-8.2 故障預警

CREATE TABLE IF NOT EXISTS ops_alert (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '運維告警ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  alert_type VARCHAR(64) COMMENT '告警類型',
  severity VARCHAR(32) COMMENT '嚴重級別',
  message TEXT COMMENT '告警信息',
  status VARCHAR(32) COMMENT '告警狀態',
  triggered_at DATETIME COMMENT '觸發時間',
  acknowledged_at DATETIME COMMENT '確認時間',
  resolved_at DATETIME COMMENT '解決時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_status (status),
  INDEX idx_severity (severity),
  INDEX idx_triggered_at (triggered_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運維告警表';

CREATE TABLE IF NOT EXISTS ops_alert_rule_m8 (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '告警規則ID',
  rule_name VARCHAR(128) NOT NULL COMMENT '規則名稱',
  device_type VARCHAR(64) COMMENT '設備類型',
  metric_name VARCHAR(128) COMMENT '指標名稱',
  condition_json JSON COMMENT '告警條件JSON',
  severity VARCHAR(32) COMMENT '告警級別',
  cooldown_min INT COMMENT '冷卻時間(分鐘)',
  notify_channel VARCHAR(64) COMMENT '通知渠道',
  enabled BOOLEAN DEFAULT TRUE COMMENT '規則是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_device_type (device_type),
  INDEX idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運維告警規則表';

CREATE TABLE IF NOT EXISTS ops_alert_workflow (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '告警工作流ID',
  alert_id BIGINT NOT NULL COMMENT '告警ID',
  step INT COMMENT '工作流步驟',
  action VARCHAR(64) COMMENT '動作',
  actor_id BIGINT COMMENT '執行人ID',
  note TEXT COMMENT '備註',
  acted_at DATETIME COMMENT '執行時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (alert_id) REFERENCES ops_alert(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (actor_id) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_alert_id (alert_id),
  INDEX idx_acted_at (acted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運維告警工作流表';

-- WI-8.3 儲能電池健康

CREATE TABLE IF NOT EXISTS ops_battery_soh (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '電池SOH記錄ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  soh_pct DECIMAL(5, 2) COMMENT '健康度(%)',
  cycle_count BIGINT COMMENT '循環次數',
  capacity_kwh DECIMAL(15, 2) COMMENT '容量(kWh)',
  internal_resistance DECIMAL(10, 4) COMMENT '內阻(mΩ)',
  temperature DECIMAL(5, 2) COMMENT '溫度(℃)',
  measured_at DATETIME COMMENT '測量時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_measured_at (measured_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電池SOH監測表';

CREATE TABLE IF NOT EXISTS ops_battery_rul_forecast (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '電池RUL預測ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  predicted_rul_days INT COMMENT '預測剩餘使用壽命(天)',
  confidence DECIMAL(5, 2) COMMENT '置信度(0-100)',
  predicted_eol_date DATE COMMENT '預測壽命終止日期',
  model_version VARCHAR(32) COMMENT '預測模型版本',
  forecasted_at DATETIME COMMENT '預測時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_forecasted_at (forecasted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電池RUL預測表';

CREATE TABLE IF NOT EXISTS ops_battery_control_strategy (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '電池控制策略ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  max_soc_pct DECIMAL(5, 2) COMMENT '最大SOC(%)',
  min_soc_pct DECIMAL(5, 2) COMMENT '最小SOC(%)',
  max_charge_rate DECIMAL(10, 2) COMMENT '最大充電率(kW)',
  max_discharge_rate DECIMAL(10, 2) COMMENT '最大放電率(kW)',
  temp_limit DECIMAL(5, 2) COMMENT '溫度限制(℃)',
  strategy_note TEXT COMMENT '策略備註',
  enabled BOOLEAN DEFAULT TRUE COMMENT '策略是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uk_device_id (device_id),
  INDEX idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='電池控制策略表';

-- WI-8.4 專家診斷

CREATE TABLE IF NOT EXISTS ops_fault_knowledge_base (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '故障知識庫ID',
  fault_code VARCHAR(32) NOT NULL UNIQUE COMMENT '故障代碼',
  fault_name VARCHAR(128) NOT NULL COMMENT '故障名稱',
  device_type VARCHAR(64) COMMENT '設備類型',
  symptoms_json JSON COMMENT '故障徵兆JSON',
  root_causes_json JSON COMMENT '根本原因JSON',
  solutions_json JSON COMMENT '解決方案JSON',
  severity VARCHAR(32) COMMENT '嚴重級別',
  reference_doc VARCHAR(256) COMMENT '參考文檔',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_fault_code (fault_code),
  INDEX idx_device_type (device_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='故障知識庫表';

CREATE TABLE IF NOT EXISTS ops_diagnosis_history (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '診斷歷史ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  fault_code VARCHAR(32) COMMENT '故障代碼',
  symptoms_input TEXT COMMENT '輸入徵兆',
  diagnosis_output TEXT COMMENT '診斷輸出',
  confidence DECIMAL(5, 2) COMMENT '置信度(0-100)',
  feedback_correct BOOLEAN COMMENT '反饋是否正確',
  diagnosed_at DATETIME COMMENT '診斷時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_diagnosed_at (diagnosed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='診斷歷史表';

CREATE TABLE IF NOT EXISTS ops_expert_report (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '專家報告ID',
  diagnosis_id BIGINT NOT NULL COMMENT '診斷歷史ID',
  report_title VARCHAR(256) COMMENT '報告標題',
  report_content LONGTEXT COMMENT '報告內容',
  created_by BIGINT COMMENT '報告作者',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (diagnosis_id) REFERENCES ops_diagnosis_history(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (created_by) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_diagnosis_id (diagnosis_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='專家診斷報告表';

-- WI-8.5 工單管理

CREATE TABLE IF NOT EXISTS ops_work_order (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '工單ID',
  order_no VARCHAR(64) NOT NULL UNIQUE COMMENT '工單號',
  title VARCHAR(256) NOT NULL COMMENT '工單標題',
  description TEXT COMMENT '工單描述',
  order_type VARCHAR(32) COMMENT '工單類型',
  priority VARCHAR(32) COMMENT '優先級',
  device_id BIGINT COMMENT '設備ID',
  site_id BIGINT COMMENT '站點ID',
  status VARCHAR(32) COMMENT '工單狀態',
  created_by BIGINT COMMENT '創建人ID',
  assigned_to BIGINT COMMENT '指派人ID',
  due_date DATE COMMENT '截止日期',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site_metadata(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (created_by) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (assigned_to) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_order_no (order_no),
  INDEX idx_status (status),
  INDEX idx_priority (priority),
  INDEX idx_assigned_to (assigned_to),
  INDEX idx_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運維工單表';

CREATE TABLE IF NOT EXISTS ops_workorder_task (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '工單任務ID',
  order_id BIGINT NOT NULL COMMENT '工單ID',
  task_name VARCHAR(256) COMMENT '任務名稱',
  description TEXT COMMENT '任務描述',
  assigned_to BIGINT COMMENT '指派人ID',
  status VARCHAR(32) COMMENT '任務狀態',
  started_at DATETIME COMMENT '開始時間',
  completed_at DATETIME COMMENT '完成時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (order_id) REFERENCES ops_work_order(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (assigned_to) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_order_id (order_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運維工單任務表';

CREATE TABLE IF NOT EXISTS ops_workorder_approval (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '工單審批ID',
  order_id BIGINT NOT NULL COMMENT '工單ID',
  approver_id BIGINT NOT NULL COMMENT '審批人ID',
  action VARCHAR(32) COMMENT '審批動作',
  comment TEXT COMMENT '審批意見',
  approved_at DATETIME COMMENT '審批時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (order_id) REFERENCES ops_work_order(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (approver_id) REFERENCES sys_user(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_order_id (order_id),
  INDEX idx_approved_at (approved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='運維工單審批表';

-- =====================================================
-- M9: 建築能碳平台 (10 work items)
-- =====================================================

-- WI-9.1 仿真

CREATE TABLE IF NOT EXISTS building_model (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '建築模型ID',
  site_id BIGINT NOT NULL COMMENT '站點ID',
  building_name VARCHAR(256) NOT NULL COMMENT '建築名稱',
  building_type VARCHAR(64) COMMENT '建築類型',
  gross_area_sqm DECIMAL(15, 2) COMMENT '總建築面積(m²)',
  floors INT COMMENT '樓層數',
  climate_zone VARCHAR(32) COMMENT '氣候帶',
  model_file_url VARCHAR(512) COMMENT '模型文件URL',
  version VARCHAR(32) COMMENT '模型版本',
  status VARCHAR(32) COMMENT '模型狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (site_id) REFERENCES site_metadata(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_site_id (site_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築能源仿真模型表';

CREATE TABLE IF NOT EXISTS building_calibration_log (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '標定日誌ID',
  model_id BIGINT NOT NULL COMMENT '模型ID',
  calibration_type VARCHAR(64) COMMENT '標定類型',
  rmse_before DECIMAL(10, 4) COMMENT '標定前RMSE',
  rmse_after DECIMAL(10, 4) COMMENT '標定後RMSE',
  params_adjusted_json JSON COMMENT '調整的參數JSON',
  calibrated_at DATETIME COMMENT '標定時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (model_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_model_id (model_id),
  INDEX idx_calibrated_at (calibrated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築模型標定日誌表';

CREATE TABLE IF NOT EXISTS building_simulation_result (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '仿真結果ID',
  model_id BIGINT NOT NULL COMMENT '模型ID',
  scenario_name VARCHAR(128) COMMENT '場景名稱',
  simulation_type VARCHAR(64) COMMENT '仿真類型',
  result_json JSON COMMENT '仿真結果JSON',
  energy_kwh DECIMAL(15, 2) COMMENT '能耗(kWh)',
  peak_power_kw DECIMAL(15, 2) COMMENT '峰值功率(kW)',
  simulated_at DATETIME COMMENT '仿真時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (model_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_model_id (model_id),
  INDEX idx_simulated_at (simulated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築能源仿真結果表';

-- WI-9.2 DRL AI智能體

CREATE TABLE IF NOT EXISTS building_drl_model (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'DRL模型ID',
  model_name VARCHAR(256) NOT NULL COMMENT '模型名稱',
  algorithm VARCHAR(64) COMMENT '算法',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  state_dim INT COMMENT '狀態維度',
  action_dim INT COMMENT '動作維度',
  model_file_url VARCHAR(512) COMMENT '模型文件URL',
  version VARCHAR(32) COMMENT '模型版本',
  status VARCHAR(32) COMMENT '模型狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='DRL智能體模型表';

CREATE TABLE IF NOT EXISTS building_drl_training_log (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '訓練日誌ID',
  model_id BIGINT NOT NULL COMMENT 'DRL模型ID',
  episode BIGINT COMMENT '訓練輪數',
  reward DECIMAL(15, 4) COMMENT '獎勵',
  loss DECIMAL(15, 4) COMMENT '損失函數值',
  epsilon DECIMAL(5, 4) COMMENT 'Epsilon值',
  training_time_sec INT COMMENT '訓練時間(秒)',
  logged_at DATETIME COMMENT '記錄時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (model_id) REFERENCES building_drl_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_model_id (model_id),
  INDEX idx_episode (episode),
  INDEX idx_logged_at (logged_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='DRL模型訓練日誌表';

CREATE TABLE IF NOT EXISTS building_drl_performance (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'DRL性能評估ID',
  model_id BIGINT NOT NULL COMMENT 'DRL模型ID',
  evaluation_period VARCHAR(32) COMMENT '評估周期',
  energy_saving_pct DECIMAL(5, 2) COMMENT '節能比例(%)',
  comfort_score DECIMAL(5, 2) COMMENT '舒適度評分(0-100)',
  cost_saving DECIMAL(15, 2) COMMENT '成本節省(元)',
  evaluated_at DATETIME COMMENT '評估時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (model_id) REFERENCES building_drl_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_model_id (model_id),
  INDEX idx_evaluated_at (evaluated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='DRL性能評估表';

-- WI-9.3 暖通控制

CREATE TABLE IF NOT EXISTS building_hvac_device (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '暖通設備ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  device_name VARCHAR(256) COMMENT '設備名稱',
  device_type VARCHAR(64) COMMENT '設備類型',
  rated_power_kw DECIMAL(15, 2) COMMENT '額定功率(kW)',
  zone VARCHAR(64) COMMENT '區域',
  floor INT COMMENT '樓層',
  status VARCHAR(32) COMMENT '設備狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_device_type (device_type),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築暖通設備表';

CREATE TABLE IF NOT EXISTS building_hvac_control_history (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '暖通控制歷史ID',
  device_id BIGINT NOT NULL COMMENT '暖通設備ID',
  control_type VARCHAR(64) COMMENT '控制類型',
  setpoint DECIMAL(10, 2) COMMENT '設定點',
  actual_value DECIMAL(10, 2) COMMENT '實際值',
  mode VARCHAR(32) COMMENT '運行模式',
  controlled_at DATETIME COMMENT '控制時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES building_hvac_device(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_controlled_at (controlled_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築暖通控制歷史表';

CREATE TABLE IF NOT EXISTS building_hvac_strategy (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '暖通策略ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  strategy_name VARCHAR(256) COMMENT '策略名稱',
  strategy_type VARCHAR(64) COMMENT '策略類型',
  config_json JSON COMMENT '配置參數JSON',
  season VARCHAR(32) COMMENT '季節',
  enabled BOOLEAN DEFAULT TRUE COMMENT '策略是否啟用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築暖通控制策略表';

-- WI-9.4 數據平台 (Note: TDengine time-series data, not MySQL)

CREATE TABLE IF NOT EXISTS building_data_quality (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '數據質量評估ID',
  sensor_id BIGINT COMMENT '傳感器ID',
  check_time DATETIME NOT NULL COMMENT '檢查時間',
  quality_score DECIMAL(5, 2) COMMENT '質量評分(0-100)',
  missing_pct DECIMAL(5, 2) COMMENT '缺失比例(%)',
  anomaly_count INT COMMENT '異常點數',
  status VARCHAR(32) COMMENT '質量狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_sensor_id (sensor_id),
  INDEX idx_check_time (check_time),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築數據質量評估表';

-- WI-9.5 碳排源

CREATE TABLE IF NOT EXISTS building_emission_source (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳排源ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  source_name VARCHAR(256) NOT NULL COMMENT '排源名稱',
  source_type VARCHAR(64) COMMENT '排源類型',
  scope VARCHAR(32) COMMENT '排放範疇(1/2/3)',
  description TEXT COMMENT '描述',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_scope (scope)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳排源表';

CREATE TABLE IF NOT EXISTS building_emission_facility (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳排源設施ID',
  source_id BIGINT NOT NULL COMMENT '碳排源ID',
  facility_name VARCHAR(256) COMMENT '設施名稱',
  facility_type VARCHAR(64) COMMENT '設施類型',
  fuel_type VARCHAR(64) COMMENT '燃料類型',
  capacity DECIMAL(15, 2) COMMENT '容量',
  unit VARCHAR(32) COMMENT '容量單位',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (source_id) REFERENCES building_emission_source(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_source_id (source_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳排源設施表';

CREATE TABLE IF NOT EXISTS building_activity_data (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '活動數據ID',
  facility_id BIGINT NOT NULL COMMENT '設施ID',
  activity_date DATE NOT NULL COMMENT '活動日期',
  activity_value DECIMAL(15, 2) COMMENT '活動數據值',
  unit VARCHAR(32) COMMENT '單位',
  data_source VARCHAR(64) COMMENT '數據來源',
  verified BOOLEAN DEFAULT FALSE COMMENT '是否已驗證',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (facility_id) REFERENCES building_emission_facility(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_facility_id (facility_id),
  INDEX idx_activity_date (activity_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳活動數據表';

CREATE TABLE IF NOT EXISTS building_emission_factor (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳排放係數ID',
  factor_name VARCHAR(256) NOT NULL COMMENT '係數名稱',
  factor_type VARCHAR(64) COMMENT '係數類型',
  region VARCHAR(64) COMMENT '地區',
  value DECIMAL(15, 6) COMMENT '係數值',
  unit VARCHAR(32) COMMENT '係數單位',
  source_standard VARCHAR(128) COMMENT '來源標準',
  effective_year INT COMMENT '有效年份',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_factor_type (factor_type),
  INDEX idx_region (region),
  INDEX idx_effective_year (effective_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳排放係數表';

-- WI-9.6 碳報告

CREATE TABLE IF NOT EXISTS building_carbon_report (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳報告ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  report_type VARCHAR(32) COMMENT '報告類型',
  reporting_period VARCHAR(32) COMMENT '報告周期',
  total_emission_kg DECIMAL(15, 2) COMMENT '總碳排放(kg)',
  scope1_kg DECIMAL(15, 2) COMMENT 'Scope1排放(kg)',
  scope2_kg DECIMAL(15, 2) COMMENT 'Scope2排放(kg)',
  scope3_kg DECIMAL(15, 2) COMMENT 'Scope3排放(kg)',
  status VARCHAR(32) COMMENT '報告狀態',
  generated_at DATETIME COMMENT '生成時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_report_type (report_type),
  INDEX idx_status (status),
  INDEX idx_generated_at (generated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳排放報告表';

CREATE TABLE IF NOT EXISTS building_report_version (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '報告版本ID',
  report_id BIGINT NOT NULL COMMENT '碳報告ID',
  version_no INT COMMENT '版本號',
  content_json JSON COMMENT '報告內容JSON',
  change_note TEXT COMMENT '變更說明',
  created_by BIGINT COMMENT '創建人ID',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (report_id) REFERENCES building_carbon_report(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (created_by) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_report_id (report_id),
  INDEX idx_version_no (version_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築報告版本表';

CREATE TABLE IF NOT EXISTS building_audit_result (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '審核結果ID',
  report_id BIGINT NOT NULL COMMENT '碳報告ID',
  auditor_name VARCHAR(128) COMMENT '審核人名稱',
  audit_org VARCHAR(256) COMMENT '審核機構',
  result VARCHAR(32) COMMENT '審核結果',
  findings TEXT COMMENT '審核發現',
  certified_at DATETIME COMMENT '認證時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (report_id) REFERENCES building_carbon_report(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_report_id (report_id),
  INDEX idx_certified_at (certified_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳核查審核結果表';

-- WI-9.7 減排規劃

CREATE TABLE IF NOT EXISTS building_carbon_analysis (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳分析ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  analysis_type VARCHAR(64) COMMENT '分析類型',
  period VARCHAR(32) COMMENT '分析周期',
  total_emission_kg DECIMAL(15, 2) COMMENT '總碳排放(kg)',
  intensity_per_sqm DECIMAL(10, 4) COMMENT '排放強度(kg/m²)',
  yoy_change_pct DECIMAL(5, 2) COMMENT '同比變化(%)',
  analyzed_at DATETIME COMMENT '分析時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_analyzed_at (analyzed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳分析表';

CREATE TABLE IF NOT EXISTS building_carbon_forecast (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳預測ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  forecast_year INT NOT NULL COMMENT '預測年份',
  predicted_emission_kg DECIMAL(15, 2) COMMENT '預測碳排放(kg)',
  scenario VARCHAR(64) COMMENT '預測場景',
  confidence DECIMAL(5, 2) COMMENT '置信度(0-100)',
  forecasted_at DATETIME COMMENT '預測時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_forecast_year (forecast_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳減排預測表';

CREATE TABLE IF NOT EXISTS building_reduction_target (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '減排目標ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  target_year INT NOT NULL COMMENT '目標年份',
  target_emission_kg DECIMAL(15, 2) COMMENT '目標排放(kg)',
  baseline_year INT COMMENT '基準年份',
  baseline_emission_kg DECIMAL(15, 2) COMMENT '基準排放(kg)',
  status VARCHAR(32) COMMENT '目標狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_target_year (target_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳減排目標表';

CREATE TABLE IF NOT EXISTS building_reduction_measure (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '減排措施ID',
  target_id BIGINT NOT NULL COMMENT '減排目標ID',
  measure_name VARCHAR(256) NOT NULL COMMENT '措施名稱',
  measure_type VARCHAR(64) COMMENT '措施類型',
  expected_reduction_kg DECIMAL(15, 2) COMMENT '預期減排量(kg)',
  actual_reduction_kg DECIMAL(15, 2) COMMENT '實際減排量(kg)',
  cost DECIMAL(15, 2) COMMENT '實施成本(元)',
  status VARCHAR(32) COMMENT '實施狀態',
  implemented_at DATETIME COMMENT '實施時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (target_id) REFERENCES building_reduction_target(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_target_id (target_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳減排措施表';

-- WI-9.8 碳資產

CREATE TABLE IF NOT EXISTS building_carbon_offset (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳抵消ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  offset_type VARCHAR(32) COMMENT '抵消類型',
  project_name VARCHAR(256) COMMENT '項目名稱',
  amount_kg DECIMAL(15, 2) COMMENT '抵消量(kg)',
  certificate_no VARCHAR(128) COMMENT '證書號',
  vintage_year INT COMMENT '年份',
  purchased_at DATETIME COMMENT '購買時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_offset_type (offset_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳抵消表';

CREATE TABLE IF NOT EXISTS building_carbon_certificate (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳證書ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  cert_type VARCHAR(64) COMMENT '證書類型',
  cert_no VARCHAR(128) NOT NULL UNIQUE COMMENT '證書號',
  issuer VARCHAR(256) COMMENT '發行機構',
  issue_date DATE COMMENT '頒發日期',
  expire_date DATE COMMENT '有效期',
  file_url VARCHAR(512) COMMENT '文件URL',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_cert_type (cert_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳證書表';

CREATE TABLE IF NOT EXISTS building_neutrality_status (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳中和狀態ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  year INT NOT NULL COMMENT '年份',
  gross_emission_kg DECIMAL(15, 2) COMMENT '總碳排放(kg)',
  total_offset_kg DECIMAL(15, 2) COMMENT '總碳抵消(kg)',
  net_emission_kg DECIMAL(15, 2) COMMENT '淨碳排放(kg)',
  is_neutral BOOLEAN COMMENT '是否碳中和',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uk_building_year (building_id, year),
  INDEX idx_year (year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳中和狀態表';

-- WI-9.9 碳核查

CREATE TABLE IF NOT EXISTS building_audit_application (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '碳核查申請ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  report_id BIGINT COMMENT '碳報告ID',
  audit_org VARCHAR(256) COMMENT '核查機構',
  audit_type VARCHAR(64) COMMENT '核查類型',
  status VARCHAR(32) COMMENT '申請狀態',
  applied_at DATETIME COMMENT '申請時間',
  scheduled_at DATETIME COMMENT '計劃核查時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (report_id) REFERENCES building_carbon_report(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_status (status),
  INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳核查申請表';

CREATE TABLE IF NOT EXISTS building_audit_workflow (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '核查工作流ID',
  application_id BIGINT NOT NULL COMMENT '申請ID',
  step INT COMMENT '工作流步驟',
  action VARCHAR(64) COMMENT '動作',
  actor BIGINT COMMENT '執行人ID',
  note TEXT COMMENT '備註',
  acted_at DATETIME COMMENT '執行時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (application_id) REFERENCES building_audit_application(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (actor) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_application_id (application_id),
  INDEX idx_acted_at (acted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳核查工作流表';

CREATE TABLE IF NOT EXISTS building_audit_certificate (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '核查證書ID',
  application_id BIGINT NOT NULL COMMENT '申請ID',
  cert_no VARCHAR(128) NOT NULL UNIQUE COMMENT '證書號',
  cert_type VARCHAR(64) COMMENT '證書類型',
  issuer VARCHAR(256) COMMENT '頒發機構',
  issue_date DATE COMMENT '頒發日期',
  valid_until DATE COMMENT '有效期至',
  file_url VARCHAR(512) COMMENT '文件URL',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (application_id) REFERENCES building_audit_application(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_application_id (application_id),
  INDEX idx_cert_type (cert_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築碳核查證書表';

-- WI-9.10 數字孿生

CREATE TABLE IF NOT EXISTS building_3d_model (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '3D模型ID',
  building_id BIGINT NOT NULL COMMENT '建築模型ID',
  model_name VARCHAR(256) NOT NULL COMMENT '模型名稱',
  model_format VARCHAR(32) COMMENT '模型格式',
  file_url VARCHAR(512) COMMENT '文件URL',
  file_size BIGINT COMMENT '文件大小(字節)',
  version VARCHAR(32) COMMENT '模型版本',
  uploaded_at DATETIME COMMENT '上傳時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (building_id) REFERENCES building_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_building_id (building_id),
  INDEX idx_uploaded_at (uploaded_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築3D模型表';

CREATE TABLE IF NOT EXISTS building_3d_device_mapping (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '3D設備映射ID',
  model_id BIGINT NOT NULL COMMENT '3D模型ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  position_x DECIMAL(15, 4) COMMENT 'X坐標',
  position_y DECIMAL(15, 4) COMMENT 'Y坐標',
  position_z DECIMAL(15, 4) COMMENT 'Z坐標',
  rotation_json JSON COMMENT '旋轉角度JSON',
  scale DECIMAL(10, 4) COMMENT '縮放係數',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (model_id) REFERENCES building_3d_model(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_model_id (model_id),
  INDEX idx_device_id (device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='建築3D設備映射表';

-- =====================================================
-- M10: 整合測試 & 部署 (5 work items)
-- =====================================================

-- WI-10.1 系統整合測試

CREATE TABLE IF NOT EXISTS test_execution (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '測試執行ID',
  test_suite VARCHAR(256) NOT NULL COMMENT '測試套件',
  test_type VARCHAR(64) COMMENT '測試類型',
  environment VARCHAR(64) COMMENT '測試環境',
  status VARCHAR(32) COMMENT '執行狀態',
  total_cases INT COMMENT '總測試用例數',
  passed INT COMMENT '通過數',
  failed INT COMMENT '失敗數',
  skipped INT COMMENT '跳過數',
  started_at DATETIME COMMENT '開始時間',
  completed_at DATETIME COMMENT '完成時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_test_suite (test_suite),
  INDEX idx_status (status),
  INDEX idx_started_at (started_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統集成測試執行表';

CREATE TABLE IF NOT EXISTS test_result (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '測試結果ID',
  execution_id BIGINT NOT NULL COMMENT '測試執行ID',
  test_case_name VARCHAR(256) COMMENT '測試用例名稱',
  module VARCHAR(128) COMMENT '模塊名稱',
  status VARCHAR(32) COMMENT '測試結果',
  error_msg TEXT COMMENT '錯誤信息',
  duration_ms BIGINT COMMENT '執行時長(毫秒)',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (execution_id) REFERENCES test_execution(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_execution_id (execution_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統集成測試結果表';

CREATE TABLE IF NOT EXISTS test_defect (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '缺陷ID',
  execution_id BIGINT NOT NULL COMMENT '測試執行ID',
  test_result_id BIGINT COMMENT '測試結果ID',
  defect_title VARCHAR(256) NOT NULL COMMENT '缺陷標題',
  severity VARCHAR(32) COMMENT '嚴重級別',
  priority VARCHAR(32) COMMENT '優先級',
  assigned_to BIGINT COMMENT '指派人ID',
  status VARCHAR(32) COMMENT '缺陷狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  resolved_at DATETIME COMMENT '解決時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (execution_id) REFERENCES test_execution(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (test_result_id) REFERENCES test_result(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (assigned_to) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_execution_id (execution_id),
  INDEX idx_status (status),
  INDEX idx_severity (severity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系統集成測試缺陷表';

-- WI-10.2 硬體聯調

CREATE TABLE IF NOT EXISTS hardware_device_config (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '硬體設備配置ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  config_key VARCHAR(256) NOT NULL COMMENT '配置鍵',
  config_value VARCHAR(512) COMMENT '配置值',
  applied_at DATETIME COMMENT '應用時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uk_device_config_key (device_id, config_key),
  INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='硬體設備配置表';

CREATE TABLE IF NOT EXISTS hardware_test_log (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '硬體測試日誌ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  test_type VARCHAR(64) COMMENT '測試類型',
  test_result VARCHAR(32) COMMENT '測試結果',
  detail TEXT COMMENT '詳細信息',
  tested_by BIGINT COMMENT '測試人ID',
  tested_at DATETIME COMMENT '測試時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (tested_by) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_tested_at (tested_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='硬體測試日誌表';

CREATE TABLE IF NOT EXISTS hardware_calibration (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '硬體標定ID',
  device_id BIGINT NOT NULL COMMENT '設備ID',
  calibration_type VARCHAR(64) COMMENT '標定類型',
  before_value DECIMAL(15, 4) COMMENT '標定前值',
  after_value DECIMAL(15, 4) COMMENT '標定後值',
  standard_value DECIMAL(15, 4) COMMENT '標準值',
  deviation DECIMAL(15, 4) COMMENT '偏差',
  calibrated_by BIGINT COMMENT '標定人ID',
  calibrated_at DATETIME COMMENT '標定時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (device_id) REFERENCES device_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (calibrated_by) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_device_id (device_id),
  INDEX idx_calibrated_at (calibrated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='硬體標定表';

-- WI-10.3 性能&安全測試

CREATE TABLE IF NOT EXISTS test_performance_log (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '性能測試日誌ID',
  test_name VARCHAR(256) COMMENT '測試名稱',
  scenario VARCHAR(128) COMMENT '測試場景',
  concurrent_users INT COMMENT '並發用戶數',
  avg_response_ms DECIMAL(15, 2) COMMENT '平均響應時間(ms)',
  p95_response_ms DECIMAL(15, 2) COMMENT 'P95響應時間(ms)',
  p99_response_ms DECIMAL(15, 2) COMMENT 'P99響應時間(ms)',
  throughput_rps DECIMAL(15, 2) COMMENT '吞吐量(req/s)',
  error_rate_pct DECIMAL(5, 2) COMMENT '錯誤率(%)',
  tested_at DATETIME COMMENT '測試時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_test_name (test_name),
  INDEX idx_tested_at (tested_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='性能測試日誌表';

CREATE TABLE IF NOT EXISTS test_security_finding (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '安全發現ID',
  scan_tool VARCHAR(128) COMMENT '掃描工具',
  finding_type VARCHAR(64) COMMENT '發現類型',
  severity VARCHAR(32) COMMENT '嚴重級別',
  title VARCHAR(256) COMMENT '標題',
  description TEXT COMMENT '描述',
  affected_component VARCHAR(256) COMMENT '受影響組件',
  remediation TEXT COMMENT '補救措施',
  status VARCHAR(32) COMMENT '處理狀態',
  found_at DATETIME COMMENT '發現時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_severity (severity),
  INDEX idx_status (status),
  INDEX idx_found_at (found_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='安全測試發現表';

-- WI-10.4 UAT

CREATE TABLE IF NOT EXISTS uat_checklist_item (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'UAT檢查項ID',
  module VARCHAR(128) COMMENT '模塊',
  feature VARCHAR(256) COMMENT '功能',
  description TEXT COMMENT '描述',
  acceptance_criteria TEXT COMMENT '驗收條件',
  status VARCHAR(32) COMMENT '狀態',
  tester BIGINT COMMENT '測試人ID',
  tested_at DATETIME COMMENT '測試時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (tester) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_module (module),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='UAT檢查清單表';

CREATE TABLE IF NOT EXISTS uat_feedback (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'UAT反饋ID',
  checklist_id BIGINT NOT NULL COMMENT '檢查項ID',
  user_name VARCHAR(128) COMMENT '反饋用戶',
  feedback_type VARCHAR(64) COMMENT '反饋類型',
  description TEXT COMMENT '反饋描述',
  screenshot_url VARCHAR(512) COMMENT '截圖URL',
  submitted_at DATETIME COMMENT '提交時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (checklist_id) REFERENCES uat_checklist_item(id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_checklist_id (checklist_id),
  INDEX idx_submitted_at (submitted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='UAT反饋表';

CREATE TABLE IF NOT EXISTS uat_issue (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'UAT問題ID',
  feedback_id BIGINT NOT NULL COMMENT '反饋ID',
  title VARCHAR(256) COMMENT '問題標題',
  severity VARCHAR(32) COMMENT '嚴重級別',
  status VARCHAR(32) COMMENT '問題狀態',
  assigned_to BIGINT COMMENT '指派人ID',
  resolved_at DATETIME COMMENT '解決時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (feedback_id) REFERENCES uat_feedback(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (assigned_to) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_feedback_id (feedback_id),
  INDEX idx_status (status),
  INDEX idx_severity (severity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='UAT問題表';

-- WI-10.5 培訓維保

CREATE TABLE IF NOT EXISTS support_ticket (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '支持工單ID',
  ticket_no VARCHAR(64) NOT NULL UNIQUE COMMENT '工單號',
  title VARCHAR(256) NOT NULL COMMENT '工單標題',
  description TEXT COMMENT '工單描述',
  category VARCHAR(64) COMMENT '分類',
  priority VARCHAR(32) COMMENT '優先級',
  status VARCHAR(32) COMMENT '狀態',
  submitted_by BIGINT COMMENT '提交人ID',
  assigned_to BIGINT COMMENT '指派人ID',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  resolved_at DATETIME COMMENT '解決時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (submitted_by) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (assigned_to) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_ticket_no (ticket_no),
  INDEX idx_status (status),
  INDEX idx_priority (priority),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支持工單表';

CREATE TABLE IF NOT EXISTS support_knowledge_base (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '知識庫ID',
  title VARCHAR(256) NOT NULL COMMENT '標題',
  category VARCHAR(64) COMMENT '分類',
  content LONGTEXT COMMENT '內容',
  tags VARCHAR(256) COMMENT '標籤',
  author_id BIGINT COMMENT '作者ID',
  view_count BIGINT DEFAULT 0 COMMENT '瀏覽次數',
  status VARCHAR(32) COMMENT '狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (author_id) REFERENCES sys_user(id) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX idx_category (category),
  INDEX idx_status (status),
  FULLTEXT INDEX ft_title_content (title, content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支持知識庫表';

CREATE TABLE IF NOT EXISTS training_course (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '培訓課程ID',
  course_name VARCHAR(256) NOT NULL COMMENT '課程名稱',
  description TEXT COMMENT '課程描述',
  target_audience VARCHAR(256) COMMENT '目標受眾',
  duration_hours INT COMMENT '課程時長(小時)',
  instructor VARCHAR(128) COMMENT '講師',
  material_url VARCHAR(512) COMMENT '學習材料URL',
  status VARCHAR(32) COMMENT '課程狀態',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='培訓課程表';

CREATE TABLE IF NOT EXISTS training_user_progress (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '培訓進度ID',
  course_id BIGINT NOT NULL COMMENT '課程ID',
  user_id BIGINT NOT NULL COMMENT '用戶ID',
  progress_pct INT COMMENT '進度(%)',
  score DECIMAL(5, 2) COMMENT '成績',
  started_at DATETIME COMMENT '開始時間',
  completed_at DATETIME COMMENT '完成時間',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '創建時間',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
  FOREIGN KEY (course_id) REFERENCES training_course(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uk_course_user (course_id, user_id),
  INDEX idx_user_id (user_id),
  INDEX idx_completed_at (completed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='培訓用戶進度表';