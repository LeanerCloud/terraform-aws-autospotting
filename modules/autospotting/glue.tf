# ──── Glue & Athena (conditional on enable_cost_dashboard) ────

resource "aws_glue_catalog_database" "cost_data" {
  count = var.enable_cost_dashboard ? 1 : 0
  name  = var.glue_database_name != "" ? var.glue_database_name : "autospotting_cost_data"
}

# cost_history — Historical cost snapshots (13 columns + 3 partition keys)
resource "aws_glue_catalog_table" "cost_history" {
  count         = var.enable_cost_dashboard ? 1 : 0
  name          = "cost_history"
  database_name = aws_glue_catalog_database.cost_data[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_history[0].id}/cost-history/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "timestamp"
      type = "timestamp"
    }
    columns {
      name = "account_id"
      type = "string"
    }
    columns {
      name = "asg_name"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "autospotting_enabled"
      type = "boolean"
    }
    columns {
      name = "instance_count"
      type = "int"
    }
    columns {
      name = "spot_instance_count"
      type = "int"
    }
    columns {
      name = "ondemand_instance_count"
      type = "int"
    }
    columns {
      name = "current_hourly_cost"
      type = "double"
    }
    columns {
      name = "ondemand_hourly_cost"
      type = "double"
    }
    columns {
      name = "spot_hourly_cost"
      type = "double"
    }
    columns {
      name = "actual_hourly_savings"
      type = "double"
    }
    columns {
      name = "potential_hourly_savings"
      type = "double"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }
}

# events — Instance replacement and spot interruption events (23 columns + 3 partition keys)
resource "aws_glue_catalog_table" "events" {
  count         = var.enable_cost_dashboard ? 1 : 0
  name          = "events"
  database_name = aws_glue_catalog_database.cost_data[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_history[0].id}/events/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "event_type"
      type = "string"
    }
    columns {
      name = "account_id"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "asg_name"
      type = "string"
    }
    columns {
      name = "old_instance_id"
      type = "string"
    }
    columns {
      name = "old_instance_type"
      type = "string"
    }
    columns {
      name = "old_lifecycle"
      type = "string"
    }
    columns {
      name = "new_instance_id"
      type = "string"
    }
    columns {
      name = "new_instance_type"
      type = "string"
    }
    columns {
      name = "new_lifecycle"
      type = "string"
    }
    columns {
      name = "reason"
      type = "string"
    }
    columns {
      name = "estimated_savings"
      type = "double"
    }
    columns {
      name = "old_hourly_price"
      type = "double"
    }
    columns {
      name = "new_hourly_price"
      type = "double"
    }
    columns {
      name = "config_changes"
      type = "string"
    }
    columns {
      name = "affected_asgs"
      type = "string"
    }
    columns {
      name = "success_count"
      type = "int"
    }
    columns {
      name = "failure_count"
      type = "int"
    }
    columns {
      name = "estimated_monthly_savings"
      type = "double"
    }
    columns {
      name = "estimated_monthly_impact"
      type = "double"
    }
    columns {
      name = "current_asg_capacity"
      type = "int"
    }
    columns {
      name = "user_id"
      type = "string"
    }
    columns {
      name = "user_email"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }
}

# spot_prices — Historical spot price observations (7 columns + 3 partition keys)
resource "aws_glue_catalog_table" "spot_prices" {
  count         = var.enable_cost_dashboard ? 1 : 0
  name          = "spot_prices"
  database_name = aws_glue_catalog_database.cost_data[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_history[0].id}/spot-prices/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "instance_type"
      type = "string"
    }
    columns {
      name = "availability_zone"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "spot_price"
      type = "double"
    }
    columns {
      name = "on_demand_price"
      type = "double"
    }
    columns {
      name = "savings_percentage"
      type = "double"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }
}

# launch_events — Instance launch attempts and outcomes (14 columns + 3 partition keys)
resource "aws_glue_catalog_table" "launch_events" {
  count         = var.enable_cost_dashboard ? 1 : 0
  name          = "launch_events"
  database_name = aws_glue_catalog_database.cost_data[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_history[0].id}/launch-events/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "event_type"
      type = "string"
    }
    columns {
      name = "account_id"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "asg_name"
      type = "string"
    }
    columns {
      name = "availability_zone"
      type = "string"
    }
    columns {
      name = "requested_instance_types"
      type = "string"
    }
    columns {
      name = "launched_instance_type"
      type = "string"
    }
    columns {
      name = "launched_instance_id"
      type = "string"
    }
    columns {
      name = "spot_price"
      type = "double"
    }
    columns {
      name = "success"
      type = "boolean"
    }
    columns {
      name = "failure_reason"
      type = "string"
    }
    columns {
      name = "failure_code"
      type = "string"
    }
    columns {
      name = "duration_ms"
      type = "int"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }
}

# savings — Aggregated savings data: hourly, daily, monthly (7 columns + 3 partition keys)
resource "aws_glue_catalog_table" "savings" {
  count         = var.enable_cost_dashboard ? 1 : 0
  name          = "savings"
  database_name = aws_glue_catalog_database.cost_data[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_history[0].id}/savings/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "account_id"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "asg_name"
      type = "string"
    }
    columns {
      name = "hourly_savings"
      type = "double"
    }
    columns {
      name = "record_type"
      type = "string"
    }
    columns {
      name = "hour"
      type = "int"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }
}

resource "aws_athena_workgroup" "cost_analytics" {
  count = var.enable_cost_dashboard ? 1 : 0
  name  = "${module.label.id}-cost-analytics"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.cost_history[0].id}/athena-results/"
    }
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-CostAnalytics"
  })
}
