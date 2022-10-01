/*
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Made by TrevorBarns
---------------------------------------------------
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
---------------------------------------------------
*/

var time_folder = "day/";
var ta_pattern = "ta/pattern_3/";
var audioPlayer = null;
var soundID = 0;
var scale = 0.6;
var pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;

const elements = 
{
	sirenbox: 	document.getElementById("sirenbox"),
	lswitch: 	document.getElementById("slide"),
	siren: 		document.getElementById("siren"),
	horn: 		document.getElementById("horn"),
	tkd: 		document.getElementById("tkd"),
	lock: 		document.getElementById("lock"),
	ta: 		document.getElementById("ta"),
}

const backup = 
{ 
	left: elements.sirenbox.style.left, 
	top: elements.sirenbox.style.top,
}


window.addEventListener('message', function(event) {
	var type = event.data._type;
	if (type == "audio") {
		playSound(event.data.file, event.data.volume);
	}else if ( type == "setResourceName" ) {
		resourceName = event.data.name
	}else if (type == "hud:setItemState") {

		var item = event.data.item;
		var state = event.data.state;
		
		switch ( item ){
			case "hud":
				if ( state == true ) {
					elements.sirenbox.style.display = "inline";
				}else{
					elements.sirenbox.style.display = "none";
				}
				break;
			case "switch":
				if ( state == true ) {
					elements.lswitch.src= "../textures/"+ time_folder + "slide_on.png";
				}else{
					elements.lswitch.src= "../textures/"+ time_folder + "slide_off.png";					
				}
				break;
			case "siren":
				if ( state == true ) {
					elements.siren.src= "../textures/" + time_folder + "siren_on.png";
				}else{
					elements.siren.src= "../textures/" + time_folder + "siren_off.png";		
				}			
				break;
			case "horn":
				if ( state == true ) {
					elements.horn.src= "../textures/" + time_folder + "horn_on.png";					
				}else{
					elements.horn.src= "../textures/" + time_folder + "horn_off.png";
				}				
				break;
			case "tkd":
				if ( state == true ) {
					elements.tkd.src= "../textures/" + time_folder + "tkd_on.png";					
				}else{
					elements.tkd.src= "../textures/" + time_folder + "tkd_off.png";
				}			
				break;			
			case "lock":
				if ( state == true ) {
					elements.lock.src= "../textures/" + time_folder + "lock_on.png";					
				}else{
					elements.lock.src= "../textures/" + time_folder + "lock_off.png";
				}				
				break;
			case "ta":
				if ( state == 1 ) {
					elements.ta.src = "../textures/" + ta_pattern + "ta_left.gif";
				}else if ( state == 2 ){
					elements.ta.src = "../textures/" + ta_pattern + "ta_right.gif";
				}else if ( state == 3 ){
					elements.ta.src = "../textures/" + ta_pattern + "ta_center.gif";
				}else if ( state == 0 ){
					elements.ta.src = "../textures/" + time_folder + "ta_off.gif";
				}
				break;			
			case "ta_pattern":
					ta_pattern = "ta/pattern_" + state + "/"
					break;
			case "time":
					time_folder = state + "/"
					break;
			default:
				break;
		}
	}else if ( type == "hud:setHudScale" ){
		scale = event.data.scale
		elements.sirenbox.style.transform = "scale(" + scale + " )";
	}else if ( type == "hud:getHudScale" ){
		sendData( "hud:sendHudScale", scale = scale );
	}else if ( type == "hud:setHudPosition" ){
		try{
			elements.sirenbox.style.left = event.data.pos.left;
			elements.sirenbox.style.top = event.data.pos.top;
		}catch(error)
		{}
	}else if ( type == "hud:resetPosition" ){
		elements.sirenbox.style.left = backup.left;
		elements.sirenbox.style.top = backup.top;
	}
});


// Exit HUD Move Mode 
$( document ).keyup( function( event ) {
	//					Esc				Backspace				Space
	if ( event.keyCode == 27 || event.keyCode == 9 || event.keyCode == 32 ) 
	{
		sendData( "hud:setHudPositon", data = { left: elements.sirenbox.style.left, top: elements.sirenbox.style.top } );
		sendData( "hud:setMoveState", state = false );
	}
} );

$( document ).contextmenu( function() {
		sendData( "hud:setHudPositon", data = { left: elements.sirenbox.style.left, top: elements.sirenbox.style.top } );
		sendData( "hud:setMoveState", state = false );
} );


// This function is used to send data back through to the LUA side 
function sendData( name, data ) {
	$.post( "https://lvc/" + name, JSON.stringify( data ), function( datab ) {
		if ( datab != "ok" ) {
			console.log( datab );
		}            
	} );
}


//Credit to xotikorukx playSound Fn.
function playSound(file, volume){
  if (audioPlayer != null) {
	audioPlayer.pause();
  }

  soundID++;

  audioPlayer = new Audio("../sounds/" + file + ".ogg");
  audioPlayer.volume = volume;
  var didPlayPromise = audioPlayer.play();

  if (didPlayPromise === undefined) {
	audioPlayer = null; //The audio player crashed. Reset it so it doesn't crash the next sound.
  } else {
	didPlayPromise.then(_ => { //This does not execute until the audio is playing.
	}).catch(error => {
	  audioPlayer = null; //The audio player crashed. Reset it so it doesn't crash the next sound.
	})
  }
}
  
  
// Drag to move functions below.
elements.sirenbox.onmousedown = dragMouseDown;

function dragMouseDown(e) {
  e = e || window.event;
  e.preventDefault();
  // get the mouse cursor position at startup:
  pos3 = e.clientX;
  pos4 = e.clientY;
  document.onmouseup = closeDragElement;
  // call a function whenever the cursor moves:
  document.onmousemove = elementDrag;
}

function elementDrag(e) {
  e = e || window.event;
  e.preventDefault();
  // calculate the new cursor position:
  pos1 = pos3 - e.clientX;
  pos2 = pos4 - e.clientY;
  pos3 = e.clientX;
  pos4 = e.clientY;
  // set the element's new position:
  elements.sirenbox.style.top = (elements.sirenbox.offsetTop - pos2) + "px";
  elements.sirenbox.style.left = (elements.sirenbox.offsetLeft - pos1) + "px";
}

function closeDragElement() {
  // stop moving when mouse button is released:
  document.onmouseup = null;
  document.onmousemove = null;
}
