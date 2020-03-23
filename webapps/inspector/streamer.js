/*
Copyright © 2015 Infrared5, Inc. All rights reserved.

The accompanying code comprising examples for use solely in conjunction with Red5 Pro (the "Example Code") 
is  licensed  to  you  by  Infrared5  Inc.  in  consideration  of  your  agreement  to  the  following  
license terms  and  conditions.  Access,  use,  modification,  or  redistribution  of  the  accompanying  
code  constitutes your acceptance of the following license terms and conditions.

Permission is hereby granted, free of charge, to you to use the Example Code and associated documentation 
files (collectively, the "Software") without restriction, including without limitation the rights to use, 
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
persons to whom the Software is furnished to do so, subject to the following conditions:

The Software shall be used solely in conjunction with Red5 Pro. Red5 Pro is licensed under a separate end 
user  license  agreement  (the  "EULA"),  which  must  be  executed  with  Infrared5,  Inc.   
An  example  of  the EULA can be found on our website at: https://account.red5pro.com/assets/LICENSE.txt.

The above copyright notice and this license shall be included in all copies or portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,  INCLUDING  BUT  
NOT  LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY, FITNESS  FOR  A  PARTICULAR  PURPOSE  AND  
NONINFRINGEMENT.   IN  NO  EVENT  SHALL INFRARED5, INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN  AN  ACTION  OF  CONTRACT,  TORT  OR  OTHERWISE,  ARISING  FROM,  OUT  OF  OR  IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
var initialAudioTIme = 0;
var initialAudioDelta = 0xFFFFFF;
var compareAudioDelta = 0xFFFFFF;
var audiobr;
var videobr;
var videojitter;
var tbr;
var drift;
//on load
function startStream(){
	console.log("Start stream");
	var ctx = document.getElementById('myChart').getContext('2d');
	window.myChart = new Chart(ctx, config);
	setInterval(doStream, 1000);
	setInterval(doLogouts, 2000);
  audiobr = document.getElementById("audiobr");
  videobr = document.getElementById("videobr");
  videojitter = document.getElementById("videojitter");
  tbr = document.getElementById("tbr");
  drift = document.getElementById("audiodrift");
}
//on interval
function doStream(){
	
	var urival = document.getElementById("streamname");
	 var s = document.createElement("script");
	    s.src = "streamapi.js?path="+urival.value;
	    document.body.appendChild(s);
}
function doLogouts(){
	
	
	 var s = document.createElement("script");
	    s.src = "streamapi.js?internals=1";
	    document.body.appendChild(s);
}
//on jsonp
function onStreamer(data){
	window.streamerdata=data;	
}
//This data set grows to about 500 elelments and then FIFOs
function onLogout(data){
	console.log(data);
}
var chartColors = {
		red: 'rgb(255, 99, 132)',
		orange: 'rgb(255, 159, 64)',
		yellow: 'rgb(255, 205, 86)',
		green: 'rgb(75, 192, 192)',
		blue: 'rgb(54, 162, 235)',
		purple: 'rgb(153, 102, 255)',
		grey: 'rgb(201, 203, 207)'
	};

// on chart refresh.
//pick up new data points. 
function onRefresh(chart) {
	if(!window.streamerdata){
		return;
	}
	var ajit=0;
	var vjit=0;
	var abr=0;
	var vbr=0;
	var vtlimit=400;
	var atlimit=800;
	var pslimit=vtlimit+atlimit;
	var slider = document.getElementById("myRange");
	//get ref video time.
	var dataset = chart.config.data.datasets[0];
	//limit
	while(dataset.data.length>vtlimit){
		dataset.data.shift();
	}
	//initial
	if(dataset.data.length<1){
		for(i in window.streamerdata){
			//filter for video		
			if( window.streamerdata[i].type=="audio"){
				continue;
			}
			dataset.data.push({
				x:window.streamerdata[i].time,
				y: window.streamerdata[i].delta
			});
		}
	}else{
		var t = dataset.data[dataset.data.length-1];
		var dmin=0xFFFF;
		var dmax=-0xFFFF;
		for(i in window.streamerdata){
			//filter for repeats and video.
			if(window.streamerdata[i].type=="audio" ){
				continue;
			}
			if( window.streamerdata[i].delta<dmin){
				dmin= window.streamerdata[i].delta;
			}
			if( window.streamerdata[i].delta>dmax){
				dmax= window.streamerdata[i].delta;
			}
			//no repeats
			if(t.x>=window.streamerdata[i].time  ){
				continue;
			}		
			
			dataset.data.push({
				x:window.streamerdata[i].time,
				y: window.streamerdata[i].delta
			});
		}
		vjit = dmax-dmin;
	}
	compareAudioDelta = 0xFFFFFF;	
	//get ref			
	dataset = chart.config.data.datasets[1];
	//limit
	while(dataset.data.length>atlimit){
		dataset.data.shift();
	}
	//initial
	if(dataset.data.length<1){
		var candidateTIme=0;
		var candidateDelta = 0xFFFFFF
		for(i in window.streamerdata){
			//filter for audio.
			if(window.streamerdata[i].type=="video"){
				continue;
			}
			
			if(candidateDelta>window.streamerdata[i].delta){
				candidateTIme=window.streamerdata[i].time,
				candidateDelta=window.streamerdata[i].delta;
				compareAudioDelta=window.streamerdata[i].delta;	
			}
			dataset.data.push({
				x:window.streamerdata[i].time,
				y: window.streamerdata[i].delta
			});
		}
		
		if(initialAudioDelta == 0xFFFFFF ){
			initialAudioTIme=candidateTIme;
			initialAudioDelta=candidateDelta;
		}
		
	}else{
		var dur = 1;
		var candidateTIme=0;
		var t = dataset.data[dataset.data.length-1];			
		for(i in window.streamerdata){
			if(window.streamerdata[i].type=="audio"){
				dur= window.streamerdata[i].time-t.x;
				abr+=window.streamerdata[i].size;
				if(compareAudioDelta>window.streamerdata[i].delta){
					compareAudioDelta=window.streamerdata[i].delta;
					candidateTIme=window.streamerdata[i].time
				}

			}
		
			//filter for audio.
			if(t.x>=window.streamerdata[i].time || window.streamerdata[i].type=="video"){
				continue;
			}
			
			dataset.data.push({
				x: window.streamerdata[i].time,
				y: window.streamerdata[i].delta
			});
		}
		audiobr.innerText = ((abr*8)/dur)+' kbit/s';   
	}

	//get ref	
	dataset = chart.config.data.datasets[2];
	//limit
	while(dataset.data.length>pslimit){
		dataset.data.shift();
	}
	if(dataset.data.length<1){
		//initial fill.
		for(i in window.streamerdata){							
			dataset.data.push({
				x:window.streamerdata[i].time,
				y: window.streamerdata[i].size/slider.value
			});
		}
		
	}else{
		var dur = 1;
		var t = dataset.data[dataset.data.length-1];
			
		for(i in window.streamerdata){
			//filter for size of video.
			if(window.streamerdata[i].type=="video"){
				dur= window.streamerdata[i].time-t.x;
				vbr+=window.streamerdata[i].size;
			}
			//cull repeats
			if(t.x>=window.streamerdata[i].time){
				continue;
			}
			//add the new ones.
			dataset.data.push({
				x: window.streamerdata[i].time,
				y: window.streamerdata[i].size/slider.value								
			});						
		}
		//console.log(j+" "+dur+" "+  ((j*8)/dur));
    videobr.innerText = ((vbr*8)/dur)+' kbit/s';
    videojitter.innerText = 'min: '+dmin +' max: ' +dmax+ ' = '+ vjit;    
	}
	tbr.innerText = ((abr + vbr)*8)/dur+' kbit/s';
	
	//get ref	
	dataset = chart.config.data.datasets[3];
	//limit
	
		while(dataset.data.length>8){
			dataset.data.shift();
			dataset.data.shift();
		}

	
	
	drift.innerText = (compareAudioDelta-initialAudioDelta);
	if(initialAudioDelta<0xFFFFFF){
		dataset.data.unshift({
			x: Date.now()-20000,
			y: initialAudioDelta
			
		});
		
		
		dataset.data.push({
			x: candidateTIme,
			y: compareAudioDelta
			
		});
	}

	//get ref video time.
	var dataset = chart.config.data.datasets[4];
	//limit
	while(dataset.data.length>atlimit*1.5){
		dataset.data.shift();
	}
	//initial
	if(dataset.data.length<1){
		for(i in window.streamerdata){
			//filter for video		
			if( window.streamerdata[i].type=="audio"){
				continue;
			}
			dataset.data.push({
				x:window.streamerdata[i].time,
				y: window.streamerdata[i].amv
			});
		}
	}else{
		var t = dataset.data[dataset.data.length-1];

		for(i in window.streamerdata){
			//filter for repeats and video.

			//no repeats
			if(t.x>=window.streamerdata[i].time  ){
				continue;
			}		
			
			dataset.data.push({
				x:window.streamerdata[i].time,
				y: window.streamerdata[i].amv
			});
		}
		vjit = dmax-dmin;
	}	
}
function cleardata(){
	chart=window.myChart;
	for(i in config.data.datasets){
		config.data.datasets[i].data=[];
	}
	initialAudioTIme = 0;
	initialAudioDelta = 0xFFFFFF;
	compareAudioDelta = 0xFFFFFF;
	chart.update();

}
var color = Chart.helpers.color;

var config = {
		type: 'line',
		data: {
			datasets: [{
				label: 'Video Time',
				backgroundColor: color(chartColors.red).alpha(1).rgbString(),
				borderColor: chartColors.red,
				fill: false,
				lineTension: 0,
				
				data: []
			},
			{
				label: 'Audio Time',
				backgroundColor: color(chartColors.blue).alpha(1).rgbString(),
				borderColor: chartColors.blue,
				fill: false,
				lineTension: 0,
				
				data: []
			},
			{
				label: 'Packet Byte Size',				
				backgroundColor: color(chartColors.orange).alpha(.25).rgbString(),
				borderColor: chartColors.orange,
				borderWidth: 1,				
				data: []
			},
			{
				label: 'Overall Audio Drift',
				
				backgroundColor: color(chartColors.green).alpha(.75).rgbString(),
				borderColor: chartColors.green,
				fill: true,							
				data: []
			},
			{
				label: 'A-V',
				
				backgroundColor: color(chartColors.grey).alpha(1).rgbString(),
				borderColor: chartColors.grey,
				fill: true,							
				data: []
			}]
		},
		options: {
			
			scales: {
				xAxes: [{
					type: 'realtime',
					realtime: {
						duration: 20000,
						refresh: 2000,
						delay: 0000,
						onRefresh: onRefresh
					}
				}],
				yAxes: [{

				}]
			},
			tooltips: {
				mode: 'nearest',
				intersect: false
			},
			hover: {
				mode: 'nearest',
				intersect: false
			}
		}
	};

