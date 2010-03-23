Please read this fully before attempting to use this software.

'downtime.rb' is a smallish program designed to do one thing:
    Manage reoccuring Nagios downtimes from the command-line in a single script.

What can it do?
    - Add reoccuring service downtimes from the command-line
    - Schedule downtimes with Nagios from a cronjob
    - Display a list of currently scheduled downtimes
    - Supports multiple services per host
    - Has a setup mode(!)

So what's missing?
    - Host downtimes:
        On the plate, just not ready for it yet.
    - Deleting downtimes:
        I'm still noodling out the logic for that.
        This is where not having a formal programming education bites me sometimes.
    - Error Checking
        There simple isn't any. I haven't started it yet beyond stub methods.
    - Service Validation
        This project is also a chance to revist my Nagios parsing library.
        End goal is to validate additions against Nagios.
    - Some unit tests
        Cause we all screw up sometimes

How do I use it?
    One of the design goals (heh) was to ensure that the script was fairly self-contained.
    No external gem dependencies. No multiple file library path bullshit. Just one script.

    There are three config files - downtime.cfg, svc_schedule.cfg and host_schedule.cfg.
    These files are YAML so you can conceivably edit them yourself however with no error
    checking, don't screw it up.

    You do NOT need to create these files yourself. The script has an initialize option that
    will do it for you.

No really, show me how to use it!
    You should have two files wherever you extracted the file - this one and the script.
    As with any other program, there's a "-h" option for help:

    "Usage: downtime.rb [options]
    Ruby script to schedule reoccuring downtime. Configuration is defined in config.yaml.
                Schedules are defined in 'host_schedule.yaml' and 'service_schedule.yaml'
      -v, --verbose                    Run Verbosely
      -d, --display                    Display current configuration and schedules
      -c, --config c                   Config file to use. Defaults /etc/nagios/downtime.cfg
      -a, --add                        Schedule a new downtime.
      -r, --remove                     Remove a downtime.
      -i, --initialize                 Initialize a new configuration
      -h, --help                       Show this message"

    The first step, after running "-h" should be to initialize a config. I would suggest
    doing this in a temporary directory at first. I've tested this part pretty extensively
    but as I said, no warranty.

    The initialization script will ask you two questions:
    - Where is the nagios external command file?
    - Where do I store my configs?

    This information will be used to create a downtime.cfg and the schedule files. No trailing slashes.
    After you've performed an initalization, you should probably add some services (downtime.rb -c /path/to/configfile -a). 
    This is where things get "hairy".

    Remember I said there's currently no validation? This is where it really comes into play. Here are the rules:
        - Hostname: must match exactly with the name given in nagios for the host
        - Service: again, must match exactly with nagios
        - Start/Stop times: 24 hour time format with seconds. i.e. 01:00:00 to 03:00:00. I'll make this a bit more flexible later.
        - Occurance: currently I only support daily downtimes as that was the itch I had. I plan on expanding this later. Just enter 'daily' here.
    
    You should, at this point, verify that the script sees your changes. You can do this with the "-d" option (for display). This will print your
    config as well as the services it knows about for downtime scheduling.

    Once you've verified the services, all you need to do at that point is schedule a cronjob to run '/path/to/downtime.rb -c /path/to/config'. If you stored your config
    in /etc/nagios/, you don't even need the -c option. I schedule my job to run at midnight:

        01 0 * * * /usr/lib/nagios/plugins/downtime.rb

    The script doesn't return anything when it runs (unless I screwed up somewhere). You shouldn't need to swallow the output. If you like, you can run with the "-v" option for verbosity.

    If you're working from a temp directory and writing to a dummy nagios command file, you can just run the script and cat the command file.

That's really all there is right now. Check http://dev.lusis.org/nagios/downtime-ruby/ for updates.
