Pulse Triggering and Monitoring
===============================

Trigger and Monitor your pulse jobs from Concourse

### Running `trigger_pulse` locally

Set environment variables and provide local files to specify artifact URLs, as
consumed by lib/pulse_options.rb

#### Environment variables

```
@url = ENV['PULSE_URL']
@project_name = ENV['PULSE_PROJECT_NAME']
@username = ENV['PULSE_USERNAME']
@password = ENV['PULSE_PASSWORD']
@input_dir = ENV['INPUT_DIR'] if @input_required
@output_dir = ENV['OUTPUT_DIR'] if @output_required
```

#### Local files to specify artifact URLs

When these scripts run in Concourse, the typical directory structure will look
like:

```
<current working directory>
├── gpdb_src
│   └── ...
├── installer_gpdb_rc
│   ├── file-from-s3.tar.gz
│   ├── url
│   └── version
├── gpdb_src_archive
│   ├── file-from-s3.tar.gz
│   ├── url
│   └── version
└── qautils_tarball
    ├── file-from-s3.tar.gz
    ├── url
    └── version
```

So if you want to specify where the URLs get pulled from, the `trigger_pulse`
script expects by default:

```
options.read_from_concourse_urls("installer_gpdb_rc/url", "gpdb_src_archive/url", "qautils_tarball/url")
```
