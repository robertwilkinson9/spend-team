# spend-team

This module provides actions when anomaly monitors are tripped.

Currently the lambda invoked prints which account would be closed, but does nothing more.
Once testing is done, the lambda could start to close accounts so we can see how quickly errant
processes are terminated.

The lambda is invoked at the action threhold, in addition an SNS notification is sent.

Alerts are set at 20%, 40%, 60% and 80% of the action threshold. These send out SNS notifications.
