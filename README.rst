Varnish Agent
=============

The Varnish Agent is a management agent for the Varnish Cache server.

In its current shape it is a communication layer for the Varnish Administration
Console (VAC) providered by Varnish Software AS.

Upon starting, the agent will attempt to register itself with the VAC instance
mentioned in the configuration file.


Getting started
---------------

Copy the example configuration file included to /etc/varnish-agent.conf and modify it
to your taste. Start the agent with the init script in /etc/init.d/. 

Verify in the VAC that the agent was able to register itself.


Source
------

This software is developed through GIT at Github::

	https://github.com/varnish/varnish-agent

Contact
-------

Issue tracking is done through Github:

	https://github.com/varnish/varnish-agent/issues

Licensing
---------

See the LICENCE.txt file for licensing information.

