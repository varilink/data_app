# DATA - App

## Perl Scripts

This directory contains Perl scripts for the [DATA - App](https://github.com/varilink/data_app) repository. Most of these are social media integration scripts.

### Social Media Integration Scripts

These scripts implement integration with Facebook, Mailchimp and X (formerly Twitter). The scripts and their functions are:

| Script                     | Function                                                                                    |
| -------------------------- | ------------------------------------------------------------------------------------------- |
| facebook-events.pl         | Posts to the DATA Facebook page about events in the DATA Diary.                             |
| facebook-get-page-token.pl | Gets a DATA Facebook page access token.                                                     |
| mailchimp-bulletin.pl      | Creates Mailchimp campaigns for sending to DATA Mailchimp subscribers.                      |
| facebook-subscribe.pl      | Posts an invitation to subscribe to the DATA Mailchimp bulletins to the DATA Facebook page. |
| x-events.pl                | Posts to the DATA X feed about events in the DATA Diary.                                    |

### Other Scripts

| Script         | Function                                                           |
| -------------- | ------------------------------------------------------------------ |
| dump-config.pl | A utility script for testing application configuration is correct. |
| sitemap.pl     | Generates a sitemap file for the DATA website for search engines.  |
