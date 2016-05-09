This script is to help facilitate various selctions of contacts matching your criteria.
It currently supports the following options:

 	Select all contacts with:
	[ ] no name
	[ ] no email
	[ ] no phone
	[ ] no address
	Apply

 * It only works on currently **Visible** contacts.
 * It works in AND mode, each selection is with all the other selections. ie. selecting No Name &   No Email, will find contacts which don't have both! 
 * To use in OR mode, please choose one option at a time and click apply. Since it ignores selected items, any new contacts matching the criteria will get added to the selection. 


Copy and paste the following as a new bookmarlet in your browser
```
(function() {
  var u = 'https://rawgit.com/VijayS1/Scripts/master/google-contacts/Google%20Contacts%20bookmarlet.js';
  var s = document.createElement('script');
  s.type = 'text/javascript';
  s.charset = 'utf-8';
  s.src = u;
  document.body.appendChild(s);
}
)();
void(0);
```

Alternatively copy & paste the contents of the .js script in the console of your contacts page. This will show the menu below the contacts menu on the left and you can use it. 


Make the interface more attractive. Use same style as google, maybe make it a dropdown?