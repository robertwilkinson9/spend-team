run "test_awsID" {
    command = plan

    variables {
	awsID = "123456789012"
    }
}

#run "test_alphaID" {
#    command = plan
#
#    variables {
#	awsID = "alphabetic"
#    }
#
#    expect_failures = [
#        var.awsID
#    ]
#}

run "test_team_spend_emails" {
    command = plan

    variables {
      team_spend_emails=["a@b.c", "d@e.f"]
    }
}
