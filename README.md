# sunpig-mt-to-wp

Notes, instructions, and scripts for moving sunpig.com from Movable Type to Wordpress

## Intro

As of 1 January 2014, sunpig.com is using Movable Type Pro version 5.14 with
Community Pack 1.83, and Professional Pack 1.63. The MT installation has two users
(@evilrooster and @sunpig), and five blogs:

* [Evilrooster Crows](http://sunpig.com/abi/)
* [Legends of the Sun Pig](http://sunpig.com/martin/)
* defunct [Quick Reviews](http://sunpig.com/martin/quickreviews/2009/)
* defunct [Bunny Tails](http://sunpig.com/bunnytails/)
* defunct, sidebar blog [Something Nice](http://sunpig.com/martin/somethingnice/2010/)

The goal is to move these blogs to self-hosted Wordpress 3.8 on the same server.

Reasons for the migration:

First of all, Movable Type fails two of my three tests for choosing a piece of (open source) software:

* Is it well documented? (yes)
* Is it under active development (no, at least not in its open source version)
* Does it have an active and supportive user community (not any more)

I still like its architectural model of static publishing, and (partly because of that) it has
a great security record, which is important if you're running your own server. I've been using MT
since version 1, and I've clung to it for sentimental and pseudo-practical reasons ("I know the
templating language really well!") for a long time, but the online world is a much different place now,
and the fact is that compared to all other avenues for writing online, MT 5's interface is
poor, and I dislike using it. As a result, I don't. I blogged less in 2013 than in any previous year.

[OpenMelody](http://openmelody.com/) was a fork of the open source version of MT 4, but it seems
to be dead now.

I was considering using [Jekyll](http://jekyllrb.com/), which is a modern static site generator:
write posts in your text editor, run a site generator from the command line, and `rsync` the generated
html files to your server. This has lots of good points: it generates static files, and it plugs
directly into my standard text editor workflow — with version control! This is great if you're a
programmer and always have access to a machine with a command line. Not so great if
`bundle exec jekyll build` makes you twitchy, or if you like the idea of occasionally posting
something from your phone. Also, no matter how you slice it, comments end up as a crazy hack.
I can see myself using jekyll for other projects, just not for our main blogs.

[Ghost](https://ghost.org/) looks interesting and new and shiny, but also: node + sqlite. Really?
And I mistrust an open source project that has a "sign up" link on its home page, but not a
"download".

[Drupal](https://drupal.org/) would probably do the job, but my impression is (perhaps incorrectly)
that it is more geared towards *sites* rather than *blogs*.

So... Wordpress. Big community, well documented, under active development. Used to have a bad rep
for security, but is a lot better than it used to be, and since version 3.7 even features an
automatic update process to apply maintenance and security patches. It also has well-established
guidelines and practices for hardening an installation. It's "the standard" these days. I have a
general preference for "off-piste" solutions, but sometimes I just want to go with something that
"just works". Mostly.

