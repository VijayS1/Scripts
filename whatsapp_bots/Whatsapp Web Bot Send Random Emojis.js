javascript:void(0);
/* 
WhatsApp Web Emoji Bot Originally written Vijay.
====================================================================================
DISCLAIMER: Use at your own risk
====================================================================================
Usage: Copy all of this script (Ctrl+A, Ctrl+C). Add a new Bookmark. In the URL 
section, paste (Ctrl+V) this script.
Visit WhatsApp Web, select your desired contact and click the Bookmark.
Press f5 to reload the page and stop the script in execution before it finishes.
You may adjust the variables to get the emoji of your desire.
Default: 10 messages of 5 emojis each from random tabs of smileys, animals, food,
symbols.
====================================================================================
*/
/* User config */
var msgcount = 10;
var emojiChars = 5; /*how many emojis to send at one time*/
var delay = 250;
/* Emoji Tabs: There is no 0, from 1 to 9.
1 - recent
2 - smileys
3 - animals
4 - food
5 - sports
6 - cars
7 - gadgets
8 - symbols (heart)
9 - flags
*/
var emojiTabs = [2,3,4,8];
var emojiOptions=[]; /* What emojis are allowed to be shown for each tab */
/* 15 emojis per row, 4 rows. Numbering starts at 1 from the left top row. */
emojiOptions[2] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30];
emojiOptions[3] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30];
emojiOptions[4] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,27,29,30,31,33,44,45,46,47,48,50,51,52,53,54,55];
emojiOptions[8] = [1,2,3,4,5,7,8,9,10,11,12,13,14,15];
/* The actual code */

function getElementByXpath(path) { return document.evaluate(path, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; }

function selectEmoji(numEmojis = 1, tabNum = -1) {
    /* requires global emojiTabs & emojiOptions. if no tabNum chooses randomly from tab pool */
    var selectedEmojis = [];
    var randomTab; var randomEmoji;
    for(var i=0; i < numEmojis; i++) {
        if (tabNum < 0) randomTab = emojiTabs[Math.floor(Math.random() * emojiTabs.length)];
        else randomTab = tabNum;
        var randomEmoji = emojiOptions[randomTab][Math.floor(Math.random() * emojiOptions[randomTab].length)];
        selectedEmojis.push([randomTab,randomEmoji]);
    }
    return selectedEmojis;
}

function partial(func /*, 0..n args */) {
  var args = Array.prototype.slice.call(arguments, 1);
  return function() {
    var allArguments = args.concat(Array.prototype.slice.call(arguments));
    return func.apply(this, allArguments);
  };
}

function sendMessage(emojiFunc, repeat=1) {
    var sEmojis = emojiFunc();
    setTimeout(function () {
        var emojiButton = getElementByXpath('//*[@id="main"]/footer/div/button[1]');
        emojiButton.click();
            setTimeout(function () {
                while (sEmojis.length > 0) {
                    [emojiTab, emojiNumber] = sEmojis.pop();
                    var tab = getElementByXpath('//*[@id="main"]/footer/span/div/div[1]/button[' + emojiTab + ']');
                    tab.click();
                    var emoji = getElementByXpath('//*[@id="main"]/footer/span/div/span/div/div/span[' + emojiNumber + ']');
                    emoji.click();
                }
                setTimeout(function () {
                    var sendButton = getElementByXpath('//*[@id="main"]/footer/div/button[2]');
                    sendButton.click();  
                    setTimeout(function () {
                        msgCounter++;        
                        if (msgCounter < repeat) {
                            sendMessage(emojiFunc, repeat);   /* recursion point */
                        }
                        else {
                            msgCounter = 0; /* reset counter */
                        }
                    }, delay);
                }, delay);
            }, delay);
  }, delay);
}

var smileys = partial(selectEmoji, emojiChars,2);
var animals = partial(selectEmoji, emojiChars,3);
var food = partial(selectEmoji, emojiChars,4);
var heart = partial(selectEmoji, emojiChars,8);
var randemoji = partial(selectEmoji, emojiChars);
var msgCounter = 0;
/* //Various Examples
sendMessage(smileys, msgcount);
sendMessage(food, msgcount);
sendMessage(heart, msgcount);
sendMessage(partial(selectEmoji,10,2), 1); //select 10 emojis from smiley tab, play 1 time
sendMessage(partial(selectEmoji,10)); //select 10 emojis from smiley tab, play default time */
sendMessage(randemoji, msgcount);