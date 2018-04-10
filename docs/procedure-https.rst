Procedure de mise en place du  HTTPS
====================================

La procédure décrit la certification HTTPS du sous-domaine « test.ecrins-parcnational.fr » grâce au service LetsEncrypt. Les manipulations ont été effectuées sur un serveur debian 9 avec apache2 installé, et un utilisateur bénéficiant des droit sudo.

Installer certbot
*****************

``sudo apt-get install python-certbot-apache``

Lancer la commande cerbot
*************************

Lancer la commande suivant pour générer des certificats et des clés pour l’ensemble des noms de domaines que vous souhaiter mettre en HTTPS.

::
  
    sudo certbot certonly --webroot --webroot-path /var/html/www --domain test.ecrins-parcnational.net --email theo.lechemia@ecrins-parcnational.fr

``certonly`` : on demande la création du certificat uniquement.

``--webroot`` : on utilise le plugin webroot qui se contente d’ajouter des fichiers dans le dossier défini via --webroot-path.

``--webroot-path`` : le chemin de votre « DocumentRoot » Apache. Certbot placera ses fichiers dans $DocumentRoot/.well-known/ pour les tests et vérifications

``--domain`` : le nom de domaine à certifier : mettre tous les sous domaines que l’on veut certifier

``--email`` : l’adresse qui recevra les notifications de Let’s Encrypt. Principalement pour rappeler de renouveler le certificat le moment venu.


Les certificats obtenus
***********************

Les certificats, se trouvent dans les dossiers : /etc/letsencrypt/live/<nom_domaine>/
Pour chaque certificat 4 fichiers sont générés :
privkey.pem : La clé privée de votre certificat. A garder confidentielle en toutes circonstances et à ne communiquer à personne quel que soit le prétexte. Vous êtes prévenus !
cert.pem : Le certificat serveur et à préciser pour les versions d’Apache < 2.4.8. Ce qui est notre cas ici.
chain.pem : Les autres certificats, SAUF le certificat serveur. Par exemple les certificats intermédiaires. Là encore pour les versions d’Apache < 2.4.8.
fullchain.pem : Logiquement, l’ensemble des certificats. La concaténation du cert.pem et du chain.pem. A utiliser cette fois-ci pour les versions d’Apache >= 2.4.8.


Configuration apache
********************

Ouvrir le fichier ``/etc/apache2/sites-availables/000-default.conf`` et le modifier de la manière suivante :


::
    
    <VirtualHost *:80>
      ServerName test.ecrins-parcnational.net
      
      RewriteEngine on
      RewriteCond %{HTTPS} !on
      RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}

    </VirtualHost>

    <VirtualHost *:443>
        ServerName test.ecrins-parcnational.net
        DocumentRoot /var/www/html

        SSLEngine on
        SSLCertificateFile /etc/letsencrypt/live/test.ecrins-parcnational.net/cert.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/test.ecrins-parcnational.net/privkey.pem
        SSLCertificateChainFile /etc/letsencrypt/live/test.ecrins-parcnational.net/chain.pem
        SSLProtocol all -SSLv2 -SSLv3
        SSLHonorCipherOrder on
        SSLCompression off
        SSLOptions +StrictRequire
        SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
        Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    </VirtualHost>

Le premier VirtualHost sert à faire la redirection automatique du http vers le https.
Le second est la configuration du https. Remplacer les chemins des fichiers de certifications par ceux généré par certbot

Activer le mode ssl et redirect puis redémarrer apache :

::

    sudo a2enmod ssl
    sudo a2enmod redirect
    sudo apachectl restart

Les fichiers configuration des sites GeoNature, TaxHub et UsersHub ne sont pas à modifier. Il seront automatiquement associé à la configuration HTTPS.


Automatiser le renouvellement du certificat
*******************************************

Le certificat fournit par LetsEncrypt n’est valable que 3 mois. Il faut donc mettre un place un renouvellement automatique.
Ajouter une tache automatique (Cron) pour renouveler une fois par semaine le certificat :



::

    sudo crontab -e
    1 8 * * Sat certbot renew --renew-hook "service apache2 reload" >> /var/log/certbot.log


Ressource : 
https://www.memoinfo.fr/tutoriels-linux/configurer-lets-encrypt-apache/