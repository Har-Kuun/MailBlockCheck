# MailBlockCheck
A quick shell script to check whether or not your server IP is blocked by famous public SMTP mail services.
If your server is blocked by many public SMTP servers, then it is better not to be used as a mail server.

Tests against the following public email servers are performed:
* Famous free email services world, such as Gmail, Outlook, Yahoo, etc.
* Famous regional free email services, such as free.fr, inbox.eu, mail.ru, etc.
* Famous Chinese free email services, such as QQ, 163.com, Sohu, Sina.
* Famous professional email services, such as MXRoute, NameCrane, FastMail, ProtonMail, Zoho, etc.

To use, simply run the following command in SSH.
```
bash <(curl https://raw.githubusercontent.com/Har-Kuun/MailBlockCheck/refs/heads/main/mailcheck.sh)
```
The script will do all relevant tests and generate a table for you at the end of its run.

![image](https://github.com/user-attachments/assets/9a518501-5337-463c-b823-87787b3a4401)

Technically you want as many "220 OK" as possible.  An "Error 554" typically means your server is blocked by this specific public SMTP service.  A "timeout" or a "no response" could be due to temporary network issue, and you can try again later.

Feel free to submit any issues that you find during using.  Happy mailing :)
