# ──── Glue & Athena (conditional on enable_cost_dashboard) ────

resource "aws_glue_catalog_database" "cost_data" {
  count = var.enable_cost_dashboard ? 1 : 0
  name  = var.glue_database_name != "" ? var.glue_database_name : "autospotting_cost_data"
}

resource "aws_glue_catalog_table" "cost_history" {
  count         = var.enable_cost_dashboard ? 1 : 0
  name          = "cost_history"
  database_name = aws_glue_catalog_database.cost_data[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_history[0].id}/cost_history/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "account_id"
      type = "string"
    }
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "cost_data"
      type = "string"
    }
  }
}

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
      name = "event_type"
      type = "string"
    }
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "data"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "spot_prices" {
  count         = var.enable_cost_dashboard ? 1 : 0
  name          = "spot_prices"
  database_name = aws_glue_catalog_database.cost_data[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_history[0].id}/spot_prices/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
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
      name = "price"
      type = "double"
    }
    columns {
      name = "timestamp"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "launch_events" {
  count         = var.enable_cost_dashboard ? 1 : 0
  name          = "launch_events"
  database_name = aws_glue_catalog_database.cost_data[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_history[0].id}/launch_events/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "instance_id"
      type = "string"
    }
    columns {
      name = "instance_type"
      type = "string"
    }
    columns {
      name = "lifecycle"
      type = "string"
    }
    columns {
      name = "timestamp"
      type = "string"
    }
  }
}

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
