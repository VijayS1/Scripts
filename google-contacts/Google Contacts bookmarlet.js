(function(){
  if (window.jQuery === undefined) {
    var done = false;
    js = document.createElement('SCRIPT');
    js.type = 'text/javascript';
    js.src = '//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js';
    js.onload = js.onreadystatechange = function() {
      if (!done && (!this.readyState || this.readyState == 'loaded' || this.readyState == 'complete')) {
        done = true;
        initMyBookmarklet();
      }
    };
    document.getElementsByTagName('head')[0].appendChild(js);
  }
  else {
    initMyBookmarklet();
  }
})();
  
var contactFields = {
	ID : 0,
	CHECKBOX : 1,
	STAR : 2,
	NAME : 3,
	EMAIL : 4,
	PHONE : 5,
	ADDRESS : 6
};

function isEmpty(contact, FieldNum) { 
	return 	(contact.children(":eq("+FieldNum+")").text() == "");
}
//isEmpty(rec1, contactFields.NAME)
//isEmpty(rec1, contactFields.EMAIL)
//isEmpty(rec1, contactFields.PHONE)
//isEmpty(rec1, contactFields.ADDRESS)

function selectContact(contact) {
	return contact.children()[contactFields.CHECKBOX].click();
}

function selectNameOnly() {
	// var num = 0;
	// $("tr.K9ln3e:visible").each(function(index) {
	// rec = $(this);
	// if (isEmpty(rec, contactFields.EMAIL) &&
		// isEmpty(rec, contactFields.PHONE) &&
		// isEmpty(rec, contactFields.ADDRESS)){	//find contacts with no text in email,phone,address
			// console.log( index + ": " + rec.text() );
			// selectContact(rec);
			// num++;
		// }
	// });
	// console.log(num + " contacts selected");
	doSelection([contactFields.EMAIL,contactFields.PHONE,contactFields.ADDRESS]);
}

function doSelection(optionsSelected) {
	var num = 0;
	console.log("starting");
	$("tr.K9ln3e:visible").each(function(index) {
		rec = $(this);
		var ans = true;
//		foreach (option in optionsselected) {
		optionsSelected.forEach(function(option){
			ans &= isEmpty(rec, option);
		});
		if (ans) {
			console.log( index + ": " + rec.text() );
			selectContact(rec);
			num++;
		}
	});
	console.log(num + " contacts selected");
}

function dumpInArray(){
  var arr = [];
  $('.modal-choices input[type="checkbox"]:checked').each(function(){
    arr.push($(this).val());
  });
  return arr; 
}

function selectButtonHandler() {
    var arr = [];
    $('.modal-choices input[type="checkbox"]:checked').each(function(){
      arr.push($(this).val());
    });
     $('#result').html(arr.join(" | "));
    doSelection(arr);
}

function addSelectionButton() {
	var selectionButton = `<div class="modal-choices">
<div><input type="checkbox" id="chk_1" name="chk_1" value="No Name"/><label for="chk_1">No Name</label></div>
<div><input type="checkbox" id="chk_2" name="chk_2" value="No Email"/><label for="chk_2">No Email</label></div>
<div><input type="checkbox" id="chk_3" name="chk_3" value="No Phone"/><label for="chk_3">No Phone</label></div>
<div><input type="checkbox" id="chk_4" name="chk_4" value="No Address"/><label for="chk_4">No Address</label></div>
<div><a href="#" id="applySelection" class="button select-roles" onclick="selectButtonHandler" role="button">Apply</a></div>
<div id="result"></div>
</div>`;
	//$("div#\\:ul").parent().append(selectionButton);
	$("div.gfqccc").append(selectionButton);
	$('#applySelection').click(selectButtonHandler);
}


//-------- from http://stackoverflow.com/a/26142061/107537
function simulateClick(elem) {
    var rect = elem.getBoundingClientRect(), // holds all position- and size-properties of element
        topEnter = rect.top,
        leftEnter = rect.left, // coordinates of elements topLeft corner
        topMid = topEnter + rect.height / 2,
        leftMid = topEnter + rect.width / 2, // coordinates of elements center
        ddelay = (rect.height + rect.width) * 2, // delay depends on elements size
        ducInit = {bubbles: true, clientX: leftMid, clientY: topMid}, // create init object
        // set up the four events, the first with enter-coordinates,
        mover = new MouseEvent('mouseover', {bubbles: true, clientX: leftEnter, clientY: topEnter}),
        // the other with center-coordinates
        mdown = new MouseEvent('mousedown', ducInit),
        mup = new MouseEvent('mouseup', ducInit),
        mclick = new MouseEvent('click', ducInit);
    // trigger mouseover = enter element at toLeft corner
    elem.dispatchEvent(mover);
    // trigger mousedown  with delay to simulate move-time to center
    window.setTimeout(function() {elem.dispatchEvent(mdown)}, ddelay);
    // trigger mouseup and click with a bit longer delay
    // to simulate time between pressing/releasing the button
    window.setTimeout(function() {
        elem.dispatchEvent(mup); elem.dispatchEvent(mclick);
    }, ddelay * 1.2);
}

//simulateClick($("div#\\:uo")[0]); //Add to Groups Button
  function initMyBookmarklet() {
    console.log("starting bookmarklet");
	addSelectionButton();
  }
