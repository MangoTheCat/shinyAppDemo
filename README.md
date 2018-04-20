# shinyAppDemo

The shinyAppDemo package has been created to demonstrate one method of packaging a Shiny application.

## Installation

``` r
devtools::install_github("mangothecat/shinyAppDemo")
```

...or...

``` r
source("https://install-github.me/mangothecat/shinyAppDemo")
```

## Run the Shiny app

There's only one exported function in the package and it runs the Shiny app:

``` r
shinyAppDemo::launchApp()
```

---

# Packaging Shiny applications - a deep dive
_(Or, how to write a Shiny app.R file that only contains a single line of code)_

This post is long overdue. The information contained herein has been built up over years of deploying and hosting Shiny apps, particularly in production environments, and mainly where those Shiny apps are very large and contain a lot of code.

Last year, during some of my conference talks, I told the story of Mango’s early adoption of Shiny and how it wasn’t always an easy path to production for us. In this post I’d like to fill in some of the technical background and provide some information about Shiny app publishing and packaging that is hopefully useful to a wider audience.

I’ve figured out some of this for myself, but the most pivotal piece of information came from Shiny creator, Joe Cheng. Joe told me some time ago, that all you really need in an app.R file is a function that returns a Shiny application object. When he told me this, I was heavily embedded in the publication side and I didn’t immediately understand the implications.

Over time though I came to understand the power and flexibility that this model provides and, to a large extent, that’s what this post is about.


# What is Shiny?

Hopefully if you’re reading this you already know, but [Shiny is a web application framework for Ri](https://shiny.rstudio.com/). It allows R users to develop powerful web applications entirely in R without having to understand HTML, CSS and JavaScript. It also allows us to embed the statistical power of R directly into those web applications.

Shiny apps generally consist of either a ui.R and a server.R (containing user interface and server-side logic respectively) or a single app.R which contains both.
Why package a Shiny app anyway?

If your app is small enough to fit comfortably in a single file, then packaging your application is unlikely to be worth it. As with any R script though, when it gets too large to be comfortably worked with as a single file, it can be useful to break it up into discrete components.

Publishing a packaged app will be more difficult, but to some extent that will depend on the infrastructure you have available to you.

# Pros of packaging

Packaging is one of the many great features of the R language. Packages are fairly straightforward, quick to create and you can build them with a host of useful features like built-in documentation and unit tests.

They also integrate really nicely into Continuous Integration (CI) pipelines and are supported by tools like Travis. You can also get test coverage reports using things like codecov.io.

They’re also really easy to share. Even if you don’t publish your package to CRAN, you can still share it on GitHub and have people install it with devtools, or build the package and share that around, or publish the package on a CRAN-like system within your organisation’s firewall.


# Cons of packaging
Before you get all excited and start to package your Shiny applications, you should be aware that -- depending on your publishing environment -- packaging a Shiny application may make it difficult or even impossible to publish to a system like Shiny Server or RStudio Connect, without first unpacking it again.


# A little bit of Mango history

This is where Mango were in the early days of our Shiny use. We had a significant disconnect between our data scientists writing the Shiny apps and the IT team tasked with supporting the infrastructure they used. This was before we’d committed to having an engineering team that could sit in the middle and provide a bridge between the two.

When our data scientists would write apps that got a little large or that they wanted robust tests and documentation for, they would stick them in packages and send them over to me to publish to our original Shiny Server. The problem was: R packages didn’t really mean anything to me at the time. I knew how to install them, but that was about as far as it went. I knew from the Shiny docs that a Shiny app needs certain files (server.R and ui.R or an app.R) file, but that wasn’t what I got, so I’d send it back to the data science team and tell them that I needed those files or I wouldn’t be able to publish it.

More than once I got back a response along the lines of, “but you just need to load it up and then do runApp()”. But, that’s just not how Shiny Server works. Over time, we’ve evolved a set of best practices around when and how to package a Shiny application.

The first step was taking the leap into understanding Shiny and R packages better. It was here that I started to work in the space between data science and IT.

# How to package a Shiny application

If you’ve seen the simple app you get when you choose to create a new Shiny application in RStudio, you’ll be familiar with the basic structure of a Shiny application. You need to have a UI object and a server function.

If you have a look inside the UI object you’ll see that it contains the html that will be used for building your user interface. It’s not everything that will get served to the user when they access the web application -- some of that is added by the Shiny framework when it runs the application -- but it covers off the elements you’ve defined yourself.

The server function defines the server-side logic that will be executed for your application. This includes code to handle your inputs and produce outputs in response.

The great thing about Shiny is that you can create something awesome quite quickly, but once you’ve mastered the basics, the only limit is your imagination.

For our purposes here, we’re going to stick with the ‘geyser’ application that RStudio gives you when you click to create a new Shiny Web Application. If you open up RStudio, and create a new Shiny app -- choosing the single file app.R version -- you’ll be able to see what we’re talking about. The small size of the geyser app makes it ideal for further study.

If you look through the code you’ll see that there are essentially three components: the UI object, the server function, and the `shinyApp()` function that actually runs the app.

Building an R package of just those three components is a case of breaking them out into the constituent parts and inserting them into a blank package structure. We have a [version of this up on GitHub](https://github.com/mangothecat/shinyAppDemo) that you can check out if you want.

The directory layout of the demo project looks like this:

```
|-- DESCRIPTION
|-- LICENSE
|-- NAMESPACE
|-- R
|   |-- launchApp.R
|   |-- shinyAppServer.R
|   `-- shinyAppUI.R
|-- README.md
|-- inst
|   `-- shinyApp
|       `-- app.R
|-- man
|   |-- launchApp.Rd
|   |-- shinyAppServer.Rd
|   `-- shinyAppUI.Rd
`-- shinyAppDemo.Rproj
```

Once the app has been adapted to sit within the standard R package structure we’re almost done. The UI object and server function don’t really need to be exported, and we’ve just put a really thin wrapper function around `shinyApp()` -- I’ve called it `launchApp()` -- which we’ll actually use to launch the app. If you install the package from GitHub with devtools, you can see it in action.

```
library(shinyAppDemo)
launchApp()
```

This will start the Shiny application running locally.

The approach outlined here also works fine with [Shiny Modules](https://shiny.rstudio.com/articles/modules.html), either in the same package, or called from a separate package.

And that’s almost it! The only thing remaining is how we might deploy this app to Shiny server (including Shiny Server Pro) or RStudio Connect.

# Publishing your packaged Shiny app

We already know that Shiny Server and RStudio Connect expect either a ui.R and a server.R or an app.R file. We’re running our application out of a package with none of this, so we won’t be able to publish it until we fix this problem.

The solution we’ve arrived at is to create a directory called ‘shinyApp’ inside the inst directory of the package. For those of you who are new to R packaging, the contents of the ‘inst’ directory are essentially ignored during the package build process, so it’s an ideal place to put little extras like this.

The name ‘shinyApp’ was chosen for consistency with Shiny Server which uses a ‘shinyApps’ directory if a user is allowed to serve applications from their home directory.

Inside this directory we create a single ‘app.R’ file with the following line in it:

```
shinyAppDemo::launchApp()
```

And that really is it. This one file will allow us to publish our packaged application under some circumstances, which we’ll discuss shortly.

Here’s where having a packaged Shiny app can get tricky, so we’re going to talk you through the options and do what we can to point out the pitfalls.

# Shiny Server and Shiny Server Pro

Perhaps surprisingly -- given that [Shiny Server](https://www.rstudio.com/products/shiny/shiny-server/) is the oldest method of Shiny app publication -- it’s also the easiest one to use with these sorts of packaged Shiny apps. There are basically two ways to publish on Shiny Server. From your home directory on the server -- also known as self-publishing -- or publishing from a central location, usually the directory ‘/srv/shiny-server’.

The central benefit of this approach is the ability to update the application just by installing a newer version of the package. Sadly though, it’s not always an easy approach to take.

## Apps served from home directory (AKA self-publishing)

The first publication method is [from a users' home directory](http://docs.rstudio.com/shiny-server/#host-per-user-application-directories). This is generally used in conjunction with RStudio Server. In the self-publishing model, Shiny Server (and Pro) expect apps to be found in a directory called ‘ShinyApps’, within the users home directory. This means that if we install a Shiny app in a package the final location of the app directory will be inside the installed package, not in the ShinyApps directory. In order to work around this, we create a link from where the app is expected to be, to where it actually is within the installed package structure.

So in the example of our package, we’d do something like this in a terminal session:

```
# make sure we’re in our home directory
cd
# change into the shinyApps directory
cd shinyApps
# create a link from our app directory inside the package
ln -s /home/sellorm/R/x86_64-pc-linux-gnu-library/3.4/shinyAppDemo/shinyApp ./testApp
```

Note: The path you will find your libraries in will differ from the above. Check by running `.libPaths()[1]` and then `dir(.libPaths()[1])` to see if that’s where your packages are installed.

Once this is done, the app should be available at ‘http://<server-address>:3838/<your_username>/<app_name>’ and can be updated by updating the installed version of the package. Update the package and the updates will be published via Shiny Server straight away.

## Apps Server from a central location (usually /srv/shiny-server)

This is essentially the same as above, but the task of publishing the application generally falls to an administrator of some sort.

Since they would have to transfer files to the server and log in anyway, it shouldn’t be too much of an additional burden to install a package while they’re there. Especially if that makes life easier from then on.

The admin would need to transfer the package to the server, install it and then create a link -- just like in the example above -- from the expected location, to the installed location.

The great thing with this approach is that when updates are due to be installed the admin only has to update the installed package and not any other files.

# RStudio Connect

[Connect](https://www.rstudio.com/products/connect/) is the next generation Shiny Server. In terms of features and performance, it’s far superior to its predecessor. One of the best features is the ability to push Shiny app code directly from the RStudio IDE. For the vast majority of users, this is a huge productivity boost, since you no longer have to wait for an administrator to publish your app for you.

Since publishing doesn’t require anyone to directly log into the server as part of the publishing process, there aren’t really any straightforward opportunities to install a custom package. This means that, in general, publishing a packaged shiny application isn’t really possible.

There’s only one real workaround for this situation that I’m aware of. If you have an internal CRAN-like repository for your custom packages, you should be able to use that to update Connect, with a little work.

You’d need to have your dev environment and Connect hooked up to the same repo. The updated app package needs to be available in that repo and installed in your dev environment. Then, you could publish and then update the single line app.R for each successive package version you publish.

Connect uses packrat under the hood, so when you publish the app.R the packrat manifest will also be sent to the server. Connect will use the manifest to decide which packages are required to run your app. If you’re using a custom package this would get picked up and installed or updated during deployment.

# shinyapps.io
It’s not currently possible to publish a packaged application to [shinyapps.io](http://www.shinyapps.io/). You’d need to make sure your app followed the accepted conventions for creating Shiny apps and only uses files, rather than any custom packages.

# Conclusion

Packaging Shiny apps can be a real productivity boon for you and your team. In situations where you can integrate that process into other processes, such as automatically running your unit tests or automated publishing it can also help you adopt devops-style workflows.

However, in some instances, the practice can actually make things worse and really slow you down. It’s essential to understand what the publishing workflow is in your organisation before embarking on any significant Shiny packaging project as this will help steer you towards the best course of action.

