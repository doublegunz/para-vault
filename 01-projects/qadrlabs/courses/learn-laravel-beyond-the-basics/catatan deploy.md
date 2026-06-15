cek versi php dan node
```
gungun@qadrlabs:$ node -v
v22.22.3
gungun@qadrlabs:$ php -v
PHP 8.3.6 (cli) (built: May 25 2026 13:12:06) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.3.6, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.6, Copyright (c), by Zend Technologies

```

saat uji coba clone dari repo pribadi
arahkan clone dari repositori pribadi atau https://github.com/qadrLabs/catatku-deploy-demo 


```
sudo mkdir -p /var/www/catatku
sudo chown -R $USER:$USER /var/www/catatku
git clone https://github.com/doublegunz/catatku.git /var/www/catatku
cd /var/www/catatku
```






bagian setup mariadb perlu ditulis step per step

```
sudo mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
haven't set the root password yet, you should just press enter here.

Enter current password for root (enter for none): 
OK, successfully used password, moving on...

Setting the root password or using the unix_socket ensures that nobody
can log into the MariaDB root user without the proper authorisation.

You already have your root account protected, so you can safely answer 'n'.

Switch to unix_socket authentication [Y/n] y
Enabled successfully!
Reloading privilege tables..
 ... Success!


You already have your root account protected, so you can safely answer 'n'.

Change the root password? [Y/n] y
New password: 
Re-enter new password: 
Password updated successfully!
Reloading privilege tables..
 ... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] y
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!

```




setup supervisor

```
gungun@qadrlabs:/var/www/catatku$ sudo nano /etc/supervisor/conf.d/catatku-worker.conf
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start catatku-worker:*
sudo supervisorctl status
catatku-worker: available
catatku-worker: added process group
catatku-worker:catatku-worker_00   STARTING  
catatku-worker:catatku-worker_01   STARTING  
```



test script deploy

```
gungun@qadrlabs:/var/www/catatku$ ./deploy.sh 

   INFO  Application is now in maintenance mode.  

From https://github.com/doublegunz/catatku
 * branch            main       -> FETCH_HEAD
Already up to date.
Installing dependencies from lock file
Verifying lock file contents can be installed on current platform.
Nothing to install, update or remove
Generating optimized autoload files
> Illuminate\Foundation\ComposerScripts::postAutoloadDump
> @php artisan package:discover --ansi

   INFO  Discovering packages.  

  laravel/sanctum ....................................................... DONE
  laravel/tinker ........................................................ DONE
  nesbot/carbon ......................................................... DONE
  nunomaduro/termwind ................................................... DONE

54 packages you are using are looking for funding.
Use the `composer fund` command to find out more!

added 63 packages, and audited 64 packages in 4s

16 packages are looking for funding
  run `npm fund` for details

2 critical severity vulnerabilities

To address all issues, run:
  npm audit fix

Run `npm audit` for details.

> build
> vite build

vite v8.0.16 building client environment for production...
✓ 3 modules transformed.
computing gzip size...
public/build/manifest.json                                      2.51 kB │ gzip:  0.43 kB
public/build/assets/instrument-sans-400-normal-Q_nF8v4l.woff2   6.85 kB
public/build/assets/instrument-sans-600-normal-BsaQcF38.woff2   6.94 kB
public/build/assets/instrument-sans-500-normal-CTEe1bJa.woff2   6.98 kB
public/build/assets/instrument-sans-400-normal-r32jotim.woff    8.96 kB
public/build/assets/instrument-sans-500-normal-CAxz3nsc.woff    9.06 kB
public/build/assets/instrument-sans-600-normal-DMks36a2.woff    9.10 kB
public/build/fonts-manifest.json                               11.19 kB │ gzip:  0.97 kB
public/build/assets/instrument-sans-400-normal-DRC__1Mx.woff2  16.86 kB
public/build/assets/instrument-sans-500-normal-Dk9ku72i.woff2  17.23 kB
public/build/assets/instrument-sans-600-normal-B7fBEWYG.woff2  17.40 kB
public/build/assets/instrument-sans-400-normal-D1W7dsQl.woff   21.24 kB
public/build/assets/instrument-sans-500-normal-Z6ESRlEs.woff   21.65 kB
public/build/assets/instrument-sans-600-normal-B9e8oLYv.woff   21.67 kB
public/build/assets/fonts-DkuEHybc.css                          4.76 kB │ gzip:  0.55 kB
public/build/assets/app-BK4ejP5Q.css                           45.51 kB │ gzip: 10.49 kB
public/build/assets/app-BvRk9kiK.js                             0.00 kB │ gzip:  0.02 kB

✓ built in 550ms

   INFO  Nothing to migrate.  


   INFO  Clearing cached bootstrap files.  

  config ......................................................... 1.99ms DONE
  cache ......................................................... 30.13ms DONE
  compiled ....................................................... 1.28ms DONE
  events ......................................................... 0.84ms DONE
  routes ......................................................... 0.89ms DONE
  views ......................................................... 77.70ms DONE


   INFO  Caching framework bootstrap, configuration, and metadata.  

  config ........................................................ 16.78ms DONE
  events ......................................................... 1.86ms DONE
  routes ........................................................ 22.02ms DONE
  views ......................................................... 49.00ms DONE


   INFO  Broadcasting queue restart signal.  


   INFO  Application is now live.  

Deploy finished.

```