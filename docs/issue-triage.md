# Issue Triage
**Triage** is the process of reviewing and labeling incoming issues, identifying any which are critical, and escalating the critical ones.

## Why We Triage
Triage sets us up for success, improves developer experience, and raises quality faster by prioritizing impactful issues. When all issues in a repository are regularly labeled, tested, and reviewed it makes it easy to know exactly where to see the highest needs to improve user experience. High quality bug reports in an organized and prioritized repository makes it easier to start working on maintenance and, in turn, helps us close the loop on user feedback.

## Labels
All issues should have a label for the general area of the app it corresponds to and a `[Type]` label (e.g. `[Type] Bug` or `[Type] Enhancement`).

Useful links to find issues that need labels:

* [Unlabeled issues](https://github.com/wordpress-mobile/WordPress-iOS/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen%20no%3Alabel)
* [Issues with no Type label](https://github.com/wordpress-mobile/WordPress-iOS/issues?q=is%3Aopen+is%3Aissue+-label%3A%22%5BType%5D+Broken+Window%22+-label%3A%22%5BType%5D+Bug%22+-label%3A%22%5BType%5D+Content+Loss%22+-label%3A%22%5BType%5D+Crash%22+-label%3A%22%5BType%5D+Enhancement%22+-label%3A%22%5BType%5D+Question%22+-label%3A%22%5BType%5D+Task%22+-label%3A%22%5BType%5D+Beta+OS%22+-label%3A%22%5BType%5D+Discovery%22+-label%3A%22%5BType%5D+Discussion%22+-label%3A%22%5BType%5D+Novice%22+-label%3A%22%5BType%5D+Tech+Debt%22)

## Prioritization
Bug reports (issues with the  `[Type] Bug` label) should also have a Priority label. Priority is assigned based on severity and impact:

| |**Low Severity**|**Medium Severity**|**High Severity**|**Critical Severity**|
|-|-|-|-|-|
|**Low Impact**|Low|Low|Normal|High|
|**Medium Impact**|Low|Normal|High|Critical|
|**High Impact**|Normal|High|Critical|Critical|

### Severity

Severity is determined by what functionality is affected and how broken it is:

* **Low:** Visual issue or edge case (doesn’t affect core/default functionality)
* **Medium:** Bug with a workaround, low priority feature is broken/non-functional, visual issue in login/signup (first impressions)
* **High**: High priority flow or feature is broken/non-functional, security issue, crash. High priority areas: login, signup, editing, stats, notifications
* **Critical:** Critical impact on data or site: data loss (posts, pages, comments), unexpected publishing

### Impact

Impact is determined by how many users are affected or how many reports we receive:

* **Low:** Non-reproducible or single user report, or estimated 0-5% of users affected.
* **Medium:** 2-4 user reports, or estimated 6-25% of users affected.
* **High:** 5+ user reports, or estimated 26-100% of users affected.

If you aren't sure how to estimate the number of users affected, use the number of user reports you can find as a starting point. The issue can be escalated later if we find a good estimate of users affected or if more user reports are noted on the issue.
