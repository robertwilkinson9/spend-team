resource "aws_ce_anomaly_subscription" "anomaly_subscription_20" {
  name      = "TeamSpend20"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["1"]
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription_40" {
  name      = "TeamSpend40"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["2"]
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription_60" {
  name      = "TeamSpend60"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["3"]
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription_80" {
  name      = "TeamSpend80"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["4"]
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription_action" {
  name      = "TeamSpendAction"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["5"]
    }
  }
}
