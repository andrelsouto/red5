<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8"%>
<%@ page import="java.net.Inet4Address,java.net.URLConnection"%>
<%@ page import="com.red5pro.server.secondscreen.net.NetworkUtil"%>
<%@ page import="java.io.*,java.util.Map,java.util.ArrayList,java.util.regex.*,java.net.URL,java.nio.charset.Charset"%>
<%
  String cookieStr = "";
  String cookieName = "storedIpAddress";
  Pattern addressPattern = Pattern.compile("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$");

  String host_success = "[Address Resolver]";
  ArrayList<String> host_errors = new ArrayList<String>();
  String ip = null;
  String hostname = request.getServerName();
  String scheme = request.getScheme();
  String localIp = NetworkUtil.getLocalIpAddress();
  boolean ipExists = false;
  boolean isSecure = scheme == "https";
  String kvUrlParams = "";
  String delimiter = ";";
  Map<String, String[]> parameters = request.getParameterMap();
  for(String parameter : parameters.keySet()) {
    if (!parameter.equals("")) {
      kvUrlParams += parameter + "=" + request.getParameter(parameter) + delimiter;
    }
  }

  // Flip localIp to null if unknown.
  // localIp = addressPattern.matcher(localIp).find() ? localIp : null;

  // First check if provided as a query parameter...
  if(request.getParameter("host") != null) {
    ip = request.getParameter("host");
    host_success = "[Address Resolver] Host provided as query parameter.";
    // ip = addressPattern.matcher(ip).find() ? ip : null;
  }

  Cookie cookie;
  Cookie[] cookies = request.getCookies();

  // If we have stored cookies check if already stored ip address by User.
  if(ip == null && cookies != null) {
    for(int i = 0; i < cookies.length; i++) {
      cookie = cookies[i];
      cookieStr += cookie.getName() + "=" + cookie.getValue() + "; ";
      if(cookie.getName().equals(cookieName)) {
        ip = cookie.getValue();
        host_success = "[Address Resolver] Host provided as cookie value.";
        // ip = addressPattern.matcher(ip).find() ? ip : null;
        break;
      }
    }
  }

  // Is a valid IP address from stored IP by User:
  if(ip == null) {

    ip = localIp;

    if(ip == null) {// && addressPattern.matcher(ip).find()) {
      // The IP returned from NetworkUtils is valid...
      host_success = "[Address Resolver] Host provided from NetworkUtils.";
    }
    else {

      // Invoke AWS service
      String errorPattern = "^Unknown.*";
      URL whatismyip = new URL("http://checkip.amazonaws.com");
      URLConnection connection = whatismyip.openConnection();
      connection.setConnectTimeout(5000);
      connection.setReadTimeout(5000);
      BufferedReader in = null;
      try {
        in = new BufferedReader(new InputStreamReader(connection.getInputStream(), "UTF-8"));
        ip = in.readLine();
        ip = "Unknown. Use ifconfig or ipconfig";
        if (ip.matches(errorPattern)) {
          ip = null;
          host_errors.add("[Address Resolver] Could not determine address from AWS service.");
        }
      }
      catch(Exception e) {
        ip = null;
        host_errors.add("[Address Resolver] Exception in request on AWS: " + e.getMessage() + ".");
      }
      finally {
        if (in != null) {
          try {
            in.close();
          }
          catch (IOException e) {
            e.printStackTrace();
          }
        }
      }

      // If failure in AWS service and/or IP still null => flag to show alert.
    }

  }

  if (isSecure) {
    String tmpIP = ip;
    ip = hostname;
    hostname = tmpIP;
    host_success = "[Address Resolver] Host determined from secure address.";
  }
  else if (ip == null) {
    ip = hostname;
    host_success = "[Address Resolver] Host determined from url.";
  }

  ipExists = ip != null && !ip.isEmpty();
  if (!ipExists) {
    host_success = "[Address Resolver] Could not determine host from service and utils.";
  }

  // Determine if is a Stream Manager host.
  String stream_manager_message = "";
  Boolean is_stream_manager = false;
  String stream_manager_token = "";
  FileReader reader = null;
  Pattern pattern = Pattern.compile("(rest\\.administratorToken=)(.*)");
  try {
    String path = "." + File.separator + "webapps" + File.separator + "streammanager" + File.separator + "WEB-INF" + File.separator + "red5-web.properties";
    File file = new File(path);
    reader = new FileReader(new File(file.getCanonicalPath()));
    BufferedReader br = new BufferedReader(reader);
    String st; 
    while ((st = br.readLine()) != null) {
      Matcher matcher = pattern.matcher(st);
      if (matcher.find()) {
        is_stream_manager = !matcher.group(2).equals("");
        stream_manager_token = matcher.group(2);
        break;
      }
    }
  } catch (Exception e) {
     // not a stream manager, assuming wrong filepath.
  } finally {
    if(reader != null) {
      try {
        reader.close();
      } catch (IOException e) {
        // 
      }
    }
  }
  stream_manager_message = "[Stream Manager] Determined host as Stream Manager: " + (is_stream_manager ? "yes" : "no") + ".";
%>
<!doctype html>
<!-- Copyright © 2015 Infrared5, Inc. All rights reserved.

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
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. -->
<html lang="eng">
  <head>
    <meta charset="utf-8">
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Welcome to the Red5 Pro Server Pages">
    <link rel="stylesheet" href="css/main.css">
    <link rel="stylesheet" href="css/modal.css">
    <link href="//fonts.googleapis.com/css?family=Lato:400,700" rel="stylesheet" type="text/css">
    <title>Red5Pro Basic Bandwidth Detection</title>
    <style>
      .form {
        background-color: #dbdbdb;
        padding: 20px;
      }
      .form-entry, .results-entry {
        display: flex;
        justify-content: flex-start;
        align-items: center;
      }
      .form-entry > input {
        font-size: 1em;
        padding-left: 10px;
      }
      .form-entry > label, .results-entry > .results-title {
        width: 50%;
        margin-right: 10px;
        text-align: right;
        color: #3b3b3b;
      }
      .results-container {
        margin-top: 20px;
        background-color: #eee;
        padding: 20px;
      }
      .results-title {
        color: #db1f26;
        font-weight: 500;
        text-transform: uppercase;
        text-align: center;
      }
      .results {
        margin-top: 20px;
      }
      .ui-button {
        color: #ffffff;
        background-color: #3580A2;
        text-align: center;
        border-radius: 0px;
        padding: 10px;
        width: 100%;
        margin-top: 20px;
        width: 100%;
        font-size: 1em;
        padding: 1em;
      }
      @media (max-width: 510px) {
        .form-entry {
          flex-direction: column;
        }
        .form-entry > label {
          width: 100%;
          text-align: left;
          margin-bottom: 10px;
          margin-right: 0px;
        }
        .form-entry > input {
          width: 100%;
        }
      }
</style>
  </head>
  <body>
    <style type="text/css">
    /* Top Bar CSS */
    #top-bar {
        padding: 16px 0 16px 0;
    }
    #top-bar-wrap {
        background-color: #3b3b3b;
    }
    #top-bar-wrap {
        border-color: #999999;
    }
    #top-bar-wrap, #top-bar-content strong {
        color: #dbdbdb;
    }
    #top-bar-content a, #top-bar-social-alt a {
        color: #dbdbdb;
    }
    #top-bar-content a:hover, #top-bar-social-alt a:hover {
        color: #db1f26;
    }
    .bar-container {
        width: 1200px;
        max-width: 90%;
        margin: 0 auto;
    }
    @media only screen and (min-width: 1024px) {
      #top-bar-content {
        float: none;
        text-align: right;
      }
    }
    @media only screen and (max-width: 1023px) {
      #top-bar-content {
        float: none;
        text-align: center;
      }
    }
    #menu-top-menu {
      letter-spacing: .6px;
      box-sizing: border-box;
      border: 0;
      outline: 0;
      vertical-align: baseline;
      font-size: 100%;
      margin: 0;
      padding: 0;
      list-style: none;
      touch-action: pan-y;
    }
    
    .menu-item {
      color: #dbdbdb;
      letter-spacing: .6px;
      box-sizing: border-box;
      border: 0;
      outline: 0;
      vertical-align: baseline;
      font-size: 100%;
      margin: 0;
      padding: 0;
      list-style: none;
      position: relative;
      white-space: normal;
      display: inline-block;
      float: none;
      margin-right: 15px;
    }
    
    .menu-link {
      text-decoration: none;
    }
    
    /* Typography CSS */
    #top-bar-content, #top-bar-social-alt {
        font-size: 13px;
        letter-spacing: .6px;
    }
    </style>
    <div id="top-bar-wrap" class="clr">
      <div id="top-bar" class="clr bar-container has-no-content">
        <div id="top-bar-inner" class="clr">
          <div id="top-bar-content" class="clr top-bar-right">
            <div id="top-bar-nav" class="navigation clr">
              <ul id="menu-top-menu" class="top-bar-menu dropdown-menu sf-menu sf-js-enabled" style="touch-action: pan-y;">
                <li id="menu-item-801" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-801"><a href="https://account.red5pro.com/register" class="menu-link">Sign Up</a></li>
                <li id="menu-item-802" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-802"><a href="https://account.red5pro.com/login" class="menu-link">Log In</a></li>
                <li id="menu-item-3017" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-3017"><a href="https://red5pro.com/contact-information/" class="menu-link">Contact Us</a></li>
                <li id="menu-item-2150" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-2150"><a href="https://calendly.com/red5-pro/15-minute-phone-call" class="menu-link">Let’s Talk!</a></li>
              </ul>
            </div>
          </div><!-- #top-bar-content -->
        </div><!-- #top-bar-inner -->
      </div><!-- #top-bar -->
    </div>
    <script src="lib/smartmenus-1.1.0/libs/jquery/jquery.js"></script>
    <link rel="stylesheet" href="lib/smartmenus-1.1.0/css/sm-core-css.css" />
    <link rel="stylesheet" href="lib/smartmenus-1.1.0/css/sm-clean/sm-clean.css" />
    <!-- smart menu clean overrides -->
    <style>
    @media (min-width: 1024px) {
      /* Switch to desktop layout
      -----------------------------------------------
         These transform the menu tree from
         collapsible to desktop (navbar + dropdowns)
      -----------------------------------------------*/
      /* start... (it's not recommended editing these rules) */
      .sm-clean ul {
        position: absolute;
        width: 12em;
      }
    
      .sm-clean li {
        float: left;
      }
    
      .sm-clean.sm-rtl li {
        float: right;
      }
    
      .sm-clean ul li, .sm-clean.sm-rtl ul li, .sm-clean.sm-vertical li {
        float: none;
      }
    
      .sm-clean a {
        white-space: nowrap;
      }
    
      .sm-clean ul a, .sm-clean.sm-vertical a {
        white-space: normal;
      }
    
      .sm-clean .sm-nowrap > li > a, .sm-clean .sm-nowrap > li > :not(ul) a {
        white-space: nowrap;
      }
    
      /* ...end */
      .sm-clean {
        /* padding: 0 10px; */
        /* background: #eeeeee; */
        /* border-radius: 100px; */
      }
      .sm-clean a, .sm-clean a:hover, .sm-clean a:focus, .sm-clean a:active, .sm-clean a.highlighted {
        padding: 12px 12px;
        color: #555555;
        border-radius: 0 !important;
      }
      .sm-clean a:hover, .sm-clean a:focus, .sm-clean a:active, .sm-clean a.highlighted {
        color: #D23600;
      }
      .sm-clean a.current {
        color: #D23600;
      }
      .sm-clean a.disabled {
        color: #bbbbbb;
      }
      .sm-clean a.has-submenu {
        padding-right: 24px;
      }
      .sm-clean a .sub-arrow {
        top: 50%;
        margin-top: -2px;
        right: 12px;
        width: 0;
        height: 0;
        border-width: 4px;
        border-style: solid dashed dashed dashed;
        border-color: #555555 transparent transparent transparent;
        background: transparent;
        border-radius: 0;
      }
      .sm-clean a .sub-arrow::before {
        display: none;
      }
      .sm-clean li {
        border-top: 0;
      }
      .sm-clean > li > ul::before,
      .sm-clean > li > ul::after {
        content: '';
        position: absolute;
        top: -18px;
        left: 30px;
        width: 0;
        height: 0;
        overflow: hidden;
        border-width: 9px;
        border-style: dashed dashed solid dashed;
        border-color: transparent transparent #bbbbbb transparent;
      }
      .sm-clean > li > ul::after {
        top: -16px;
        left: 31px;
        border-width: 8px;
        border-color: transparent transparent #fff transparent;
      }
      .sm-clean ul {
        border: 1px solid #bbbbbb;
        padding: 5px 0;
        background: #fff;
        border-radius: 5px !important;
        box-shadow: 0 5px 9px rgba(0, 0, 0, 0.2);
      }
      .sm-clean ul a, .sm-clean ul a:hover, .sm-clean ul a:focus, .sm-clean ul a:active, .sm-clean ul a.highlighted {
        border: 0 !important;
        padding: 10px 20px;
        color: #555555;
      }
      .sm-clean ul a:hover, .sm-clean ul a:focus, .sm-clean ul a:active, .sm-clean ul a.highlighted {
        background: #eeeeee;
        color: #D23600;
      }
      .sm-clean ul a.current {
        color: #D23600;
      }
      .sm-clean ul a.disabled {
        background: #fff;
        color: #cccccc;
      }
      .sm-clean ul a.has-submenu {
        padding-right: 20px;
      }
      .sm-clean ul a .sub-arrow {
        right: 8px;
        top: 50%;
        margin-top: -5px;
        border-width: 5px;
        border-style: dashed dashed dashed solid;
        border-color: transparent transparent transparent #555555;
      }
      .sm-clean .scroll-up,
      .sm-clean .scroll-down {
        position: absolute;
        display: none;
        visibility: hidden;
        overflow: hidden;
        background: #fff;
        height: 20px;
      }
      .sm-clean .scroll-up:hover,
      .sm-clean .scroll-down:hover {
        background: #eeeeee;
      }
      .sm-clean .scroll-up:hover .scroll-up-arrow {
        border-color: transparent transparent #D23600 transparent;
      }
      .sm-clean .scroll-down:hover .scroll-down-arrow {
        border-color: #D23600 transparent transparent transparent;
      }
      .sm-clean .scroll-up-arrow,
      .sm-clean .scroll-down-arrow {
        position: absolute;
        top: 0;
        left: 50%;
        margin-left: -6px;
        width: 0;
        height: 0;
        overflow: hidden;
        border-width: 6px;
        border-style: dashed dashed solid dashed;
        border-color: transparent transparent #555555 transparent;
      }
      .sm-clean .scroll-down-arrow {
        top: 8px;
        border-style: solid dashed dashed dashed;
        border-color: #555555 transparent transparent transparent;
      }
      .sm-clean.sm-rtl a.has-submenu {
        padding-right: 12px;
        padding-left: 24px;
      }
      .sm-clean.sm-rtl a .sub-arrow {
        right: auto;
        left: 12px;
      }
      .sm-clean.sm-rtl.sm-vertical a.has-submenu {
        padding: 10px 20px;
      }
      .sm-clean.sm-rtl.sm-vertical a .sub-arrow {
        right: auto;
        left: 8px;
        border-style: dashed solid dashed dashed;
        border-color: transparent #555555 transparent transparent;
      }
      .sm-clean.sm-rtl > li > ul::before {
        left: auto;
        right: 30px;
      }
      .sm-clean.sm-rtl > li > ul::after {
        left: auto;
        right: 31px;
      }
      .sm-clean.sm-rtl ul a.has-submenu {
        padding: 10px 20px !important;
      }
      .sm-clean.sm-rtl ul a .sub-arrow {
        right: auto;
        left: 8px;
        border-style: dashed solid dashed dashed;
        border-color: transparent #555555 transparent transparent;
      }
      .sm-clean.sm-vertical {
        padding: 10px 0;
        border-radius: 5px;
      }
      .sm-clean.sm-vertical a {
        padding: 10px 20px;
      }
      .sm-clean.sm-vertical a:hover, .sm-clean.sm-vertical a:focus, .sm-clean.sm-vertical a:active, .sm-clean.sm-vertical a.highlighted {
        background: #fff;
      }
      .sm-clean.sm-vertical a.disabled {
        background: #eeeeee;
      }
      .sm-clean.sm-vertical a .sub-arrow {
        right: 8px;
        top: 50%;
        margin-top: -5px;
        border-width: 5px;
        border-style: dashed dashed dashed solid;
        border-color: transparent transparent transparent #555555;
      }
      .sm-clean.sm-vertical > li > ul::before,
      .sm-clean.sm-vertical > li > ul::after {
        display: none;
      }
      .sm-clean.sm-vertical ul a {
        padding: 10px 20px;
      }
      .sm-clean.sm-vertical ul a:hover, .sm-clean.sm-vertical ul a:focus, .sm-clean.sm-vertical ul a:active, .sm-clean.sm-vertical ul a.highlighted {
        background: #eeeeee;
      }
      .sm-clean.sm-vertical ul a.disabled {
        background: #fff;
      }
    }
    
    .main-nav {
      background: #3b3b3b;
      padding: 0 20px;
      border-top: rgb(146, 146, 146) solid 1px;
    }
    
    .main-nav:after {
      clear: both;
      content: "\00a0";
      display: block;
      height: 0;
      font: 0px/0 serif;
      overflow: hidden;
    }
    
    .nav-brand {
      float: left;
      margin: 0;
    }
    
    .nav-brand a {
      display: block;
      padding: 12px 12px 12px 20px;
      color: #555;
      font-size: 22px;
      font-weight: normal;
      line-height: 17px;
      text-decoration: none;
    }
    
    .brand-icon {
      width: 200px;
    }
    
    #main-menu {
      clear: both;
    }
    
    @media (min-width: 1024px) {
      #main-menu {
        float: right;
        clear: none;
      }
      .main-nav {
        display: -ms-flexbox;
        display: -webkit-flex;
        display: flex;
        -ms-flex-align: center;
        -webkit-align-items: center;
        -webkit-box-align: center;
        align-items: center;
        justify-content: space-between;
      }
    }
    
    /* Mobile menu toggle button */
    
    .main-menu-btn {
      float: right;
      margin: 6px 10px;
      position: relative;
      display: inline-block;
      width: 29px;
      height: 52px;
      text-indent: 29px;
      white-space: nowrap;
      overflow: hidden;
      cursor: pointer;
      -webkit-tap-highlight-color: rgba(0, 0, 0, 0);
    }
    
    
    /* hamburger icon */
    
    .main-menu-btn-icon,
    .main-menu-btn-icon:before,
    .main-menu-btn-icon:after {
      position: absolute;
      top: 50%;
      left: 2px;
      height: 2px;
      width: 24px;
      background: #dbdbdb;
      -webkit-transition: all 0.25s;
      transition: all 0.25s;
    }
    
    .main-menu-btn-icon:before {
      content: '';
      top: -7px;
      left: 0;
    }
    
    .main-menu-btn-icon:after {
      content: '';
      top: 7px;
      left: 0;
    }
    
    /* x icon */
    
    #main-menu-state:checked ~ .main-menu-btn .main-menu-btn-icon {
      height: 0;
      background: transparent;
    }
    
    #main-menu-state:checked ~ .main-menu-btn .main-menu-btn-icon:before {
      top: 0;
      -webkit-transform: rotate(-45deg);
      transform: rotate(-45deg);
    }
    
    #main-menu-state:checked ~ .main-menu-btn .main-menu-btn-icon:after {
      top: 0;
      -webkit-transform: rotate(45deg);
      transform: rotate(45deg);
    }
    
    
    /* hide menu state checkbox (keep it visible to screen readers) */
    
    #main-menu-state {
      position: absolute;
      width: 1px;
      height: 1px;
      margin: -1px;
      border: 0;
      padding: 0;
      overflow: hidden;
      clip: rect(1px, 1px, 1px, 1px);
    }
    
    
    /* hide the menu in mobile view */
    
    #main-menu-state:not(:checked) ~ #main-menu {
      display: none;
    }
    
    #main-menu-state:checked ~ #main-menu {
      display: block;
    }
    
    @media (min-width: 768px) {
      .sm-clean ul {
        border: 1px solid #bbbbbb;
        padding: 5px 0;
        background: #3b3b3b;
        border-radius: 0px !important;
        color: #dbdbdb;
      }
    }
    
    @media (min-width: 1024px) {
      /* hide the button in desktop view */
      .main-menu-btn {
        position: absolute;
        top: -99999px;
      }
      /* always show the menu in desktop view */
      #main-menu-state:not(:checked) ~ #main-menu {
        display: block;
      }
      .sm-clean {
        background-color: #3b3b3b;
      }
      .sm-clean a {
        color: #dbdbdb;
      }
      .sm-clean ul {
        border: 1px solid #bbbbbb;
        padding: 5px 0;
        background: #3b3b3b;
        border-radius: 0px !important;
        color: #dbdbdb;
      }
      .sm-clean li {
        padding: 0 8px;
      }
      .sm-clean a .sub-arrow {
        margin-top: 0px;
        right: 6px;
      }
    }
    
    .sm-clean {
      background-color: #3b3b3b;
    }
    
    .sm-clean a, .sm-clean ul a {
      color: #dbdbdb;
      font-family: Lato;
      font-size: 16px;
      font-weight: 400;
    }
    
    .sm-clean a .sub-arrow, .sm-clean ul a .sub-arrow {
      border-color: #dbdbdb transparent transparent transparent;
    }
    
    .sm-clean a:hover {
      color: #db1f26;
      font-family: Lato;
      font-size: 16px;
      font-weight: 400;
    }
    
    .sm-clean a:focus, sm-clean a:active {
      color: #db1f26;
      font-family: Lato;
      font-size: 16px;
      font-weight: 400;
    }
    
    .sm-clean a .sub-arrow {
      background: 0;
    }
    </style>
    <nav class="main-nav" role="navigation">
    
      <!-- Mobile menu toggle button (hamburger/x icon) -->
      <input id="main-menu-state" type="checkbox" />
      <label class="main-menu-btn" for="main-menu-state">
        <span class="main-menu-btn-icon"></span> Toggle main menu visibility
      </label>
    
      <div class="nav-brand" href="https://www.red5pro.com" data-elementor-open-lightbox="">
        <a href="https://www.red5pro.com">
          <img alt="Red5 Pro" class="brand-icon" src="css/assets/Red5Pro_logo_white_red.svg">
            <noscript><img alt="Red5 Pro" data-src="css/assets/Red5Pro_logo_white_red.svg" class="brand-icon" src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" />
            <noscript><img src="css/assets/Red5Pro_logo_white_red.svg" class="brand-icon" alt="Red5 Pro" /></noscript>
        </a>
    </div>
    
      <!-- Sample menu definition -->
      <ul id="main-menu" class="sm sm-clean">
        <li><a href="#">Product</a>
          <ul>
            <li><a href="#">Red5 Pro</a>
              <ul>
                <li><a href="https://www.red5pro.com/red5-pro-server/">Server</a></li>
                <li><a href="https://www.red5pro.com/red5pro-mobile-sdks/">SDKs</a></li>
                <li><a href="https://www.red5pro.com/product-professional-services/">Professional Services</a></li>
              </ul>
            </li>
            <li><a href="#">Open Source</a>
              <ul>
                <li><a href="https://www.red5pro.com/open-source/">Overview</a></li>
                <li><a href="https://github.com/red5pro">Github Repos</a></li>
                <li><a href="https://www.red5pro.com/red5-media-server/">Media Server</a></li>
                <li><a href="https://www.red5pro.com/red5-rtmp-client/">RTMP Client</a></li>
                <li><a href="https://github.com/infrared5/react-native-red5pro">React Native Library</a></li>
                <li><a href="https://www.red5pro.com/open-source-cordova/">Cordova Plugin For Red5 Pro</a></li>
                <li><a href="https://www.red5pro.com/open-source-xamarin/">Xamarin Plugin for Red5 Pro</a></li>
                <li><a href="https://github.com/red5pro?utf8=%E2%9C%93&amp;q=bees&amp;type=&amp;language=">Load Testing Tools</a></li>
                <li><a href="https://www.red5pro.com/open-source-other-libraries/">Other Libraries</a></li>
              </ul>
            </li>
          </ul>
        </li>
        <li><a href="https://www.red5pro.com/pricing">Red5 Pro License Pricing</a>
          <ul>
            <li><a href="https://www.red5pro.com/pricing/">Plan Overview</a></li>
            <li><a href="https://www.red5pro.com/developer-pro/">Red5 Pro Developer License</a></li>
            <li><a href="https://www.red5pro.com/start-up-pro/">Red5 Pro Start Up Pro License</a></li>
            <li><a href="https://www.red5pro.com/growth-pro/">Red5 Pro Growth Pro License</a></li>
            <li><a href="https://www.red5pro.com/enterprise/">Red5 Pro Enterprise License</a></li>
            <li><a href="https://www.red5pro.com/mobile-sdk/">Red5 Pro Mobile SDK</a></li>
            <li><a href="https://www.red5pro.com/professional-services/">Red5 Pro and Professional Services</a></li>
            <li><a href="https://www.red5pro.com/pricing-comparison/">Red5 Pro License Pricing Comparison</a></li>
          </ul>
        </li>
        <li><a href="#">Resources</a>
          <ul>
            <li><a href="https://www.red5pro.com/webinars/">Webinars</a></li>
            <li><a href="https://www.red5pro.com/white-papers/">White Papers</a></li>
            <li><a href="https://blog.red5pro.com/">Blog</a></li>
          </ul>
         </li>
        <li><a href="#">Developer Zone</a>
          <ul>
            <li><a href="https://www.red5pro.com/developer-zone/">Overview</a></li>
            <li><a href="#">Github Links</a>
              <ul>
                <li><a href="https://github.com/Red5">Red5</a></li>
                <li><a href="https://github.com/red5pro">Red5 Pro</a></li>
              </ul>
            </li>
            <li><a href="https://qa-site.red5pro.com/docs">Introduction</a></li>
            <li><a href="https://qa-site.red5pro.com/docs/#quick-start-guides">Quick Start Guides</a></li>
            <li><a href="https://qa-site.red5pro.com/docs/streaming/">Streaming SDKs</a></li>
            <li><a href="https://qa-site.red5pro.com/docs/server/">Red5 Pro Server</a></li>
            <li><a href="https://qa-site.red5pro.com/docs/developerseries/">Developer Series</a></li>
            <li><a href="https://qa-site.red5pro.com/docs/serverside-guide/">Server-Side Guide</a></li>
            <li><a href="https://qa-site.red5pro.com/docs/autoscale/">Autoscaling + Stream Manager</a></li>
          </ul>
        </li>
        <li><a href="#">Customers &amp; Industries</a>
          <ul>
            <li><a href="https://www.red5pro.com/whos-using-red5-pro/">Who’s Using Red5 Pro</a></li>
            <li><a href="#">Industries</a>
              <ul>
                <li><a href="https://www.red5pro.com/live-auction-video-streaming/">Live Auction Video Streaming</a></li>
                <li><a href="https://www.red5pro.com/government-iot-and-surveillance-video-streaming/">Government – IoT and Surveillance</a></li>
                <li><a href="https://www.red5pro.com/video-games-and-esports-video-streaming/">Video Games and eSports</a></li>
                <li><a href="https://www.red5pro.com/social-media-video-streaming/">Social Media Video Streaming</a></li>
                <li><a href="https://www.red5pro.com/broadcast-video-streaming/">Broadcast Video Streaming</a></li>
                <li><a href="https://www.red5pro.com/online-gambling-video-streaming/">Online Gambling Video Streaming</a></li>
              </ul>
            </li>
            <li><a href="#">Case Studies</a>
              <ul>
                <li><a href="https://www.red5pro.com/novetta/">Novetta</a></li>
                <li><a href="https://www.red5pro.com/singular-live/">Singular.Live</a></li>
                <li><a href="https://www.red5pro.com/invaluable/">Invaluable</a></li>
              </ul>
            </li>
          </ul>
        </li>
        <li><a href="#">Help</a>
          <ul>
            <li><a href="https://red5pro.zendesk.com/hc/en-us">FAQs</a></li>
            <li><a href="https://red5pro.zendesk.com/hc/en-us/requests/new">Ticket Submissions</a></li>
            <li><a href="https://calendly.com/red5-pro/15-minute-phone-call">Talk to Sales</a></li>
          </ul>
        </li>
      </ul>
    </nav>
      <script src="lib/smartmenus-1.1.0/jquery.smartmenus.js"></script>
    <script>
    // SmartMenus init
    $(function() {
      var retry = function () {
        var t = setTimeout(function () {
          clearTimeout(t);
          init();
        }, 500);
      }
      var init = function () {
        if (!$ && !window.jQuery) {
          retry();
        } else if ((window.jQuery && window.jQuery().smartmenus) || ($ && $().smartmenus)) {
          ($ || jQuery)('#main-menu').smartmenus({
            subMenusSubOffsetX: 1,
            subMenusSubOffsetY: -8
          });
        } else {
          retry();
        }
      }
    
      init();
    });
    
    // SmartMenus mobile menu toggle button
    (function($) {
      var $mainMenuState = $('#main-menu-state');
      if ($mainMenuState.length) {
        // animate mobile menu
        $mainMenuState.change(function(e) {
          var $menu = $('#main-menu');
          if (this.checked) {
            $menu.hide().slideDown(250, function() { $menu.css('display', ''); });
          } else {
            $menu.show().slideUp(250, function() { $menu.css('display', ''); });
          }
        });
        // hide mobile menu beforeunload
        $(window).bind('beforeunload unload', function() {
          if ($mainMenuState[0].checked) {
            $mainMenuState[0].click();
          }
        });
      }
    })(($ || window.jQuery));
    </script>
    <div class="header-bar">
      <div id="header-field">
        <!-- view jsp_header for details on variables used. -->
        <!-- Display IP Address used through the page -->
        <div id="ip-field">
          <% if (ipExists) { %>
            <p>
              <span class="black-text">Your streaming host address is:</span>&nbsp;&nbsp;<span id="ip-address-field" class="red-text medium-font-size"><%= ip %></span>
              <br/>
              <span>
                <a id="ip-overlay-button" class="blue-text small-font-size" href="#">Why would I need to know the host address?</a>
              </span>
            </p>
          <% } else { %>
            <p><span class="black-text">Could not determine host address.</span></p>
          <% } %>
        </div>
        
        <!-- Overlay explaining what the IP Address is used for. -->
        <div id="ip-overlay" class="hidden">
          <p class="overlay-close-button"><a href="#" class="red-text">Close</a></p>
          <p>This host address needs to be provided to applications integrating with the Red5 Pro SDKs.</p>
          <p>If using the example projects from our <a id="header-github-link" class="link" href="https://github.com/red5pro?utf8=%E2%9C%93&q=streaming&type=&language=" target="_blank">Github</a>, you will enter this IP into the <strong>Host</strong> input field of the Settings menu.</p>
          <hr>
          <p class="top-nudge"><a id="ip-overlay-ip-incorrect-button" href="#" class="red-text">Not the correct host address?</a></p>
        </div>
        
        <!-- Overlay to allow User to update IP Address to be used. -->
        <div id="ip-address-overlay" class="hidden">
          <p class="overlay-close-button"><a id="ip-overlay-close" href="#" class="red-text">Close</a></p>
          <p class="bold">Do you think the server IP address above is incorrect?</p>
          <div>
            <p>Select from the following suggestions:</p>
            <table id="ip-suggestions-table">
              <tbody><tr><td class="red-text">No suggestions.</tr></td>
            </table>
          </div>
          <hr>
          <p class="black-text"> Or enter in the correct address below:</p>
          <p id="ip-input-error-field" class="hidden red-text">Invalid IP address.</p>
          <form style="display:flex;justify-content: space-evenly;">
            <input id="ip-address-input-field" style="flex: 2;" type="text">
            <button id="ip-address-input-submit" class="form-button">submit</button>
          </form>
        </div>
        <script>
        (function(window, document) {
          'use strict';
        
          // Host IP state
          var hostErrors = "<%= host_errors %>";
          if (hostErrors && hostErrors.length > 0) {
            var errors = hostErrors.substring(1, hostErrors.length - 1).split(',');
            for (var i = 0; i < errors.length; i++) {
              console.warn(errors[i]);
            }
          }
          console.log("<%= host_success %>");
          var currentIp = "<%= ip %>";
          var hasValidIp = <%= ipExists %>;
          var isSecureProtocol = <%= isSecure %>;
          var hostname = "<%= hostname %>";
          var ipAddressField = document.getElementById('ip-address-field');
          var validIpRegex = /^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$/gi;
        
          // IP Overlay
          var isOverlayShown = false;
          var isIpAddressOverlayShown = false;
        
          // Element References
          var ipOverlay = document.getElementById('ip-overlay');
          var ipAddressOverlay = document.getElementById('ip-address-overlay');
          var ipOverlayButton = document.getElementById('ip-overlay-button');
          var ipOverlayIpIncorrectButton = document.getElementById('ip-overlay-ip-incorrect-button');
          var githubLink = document.getElementById('header-github-link');
          var ipAddressInput = document.getElementById('ip-address-input-field');
          var ipAddressCloseButton = document.getElementById('ip-overlay-close');
          var ipAddressInputSubmit = document.getElementById('ip-address-input-submit');
          var ipAddressErrorField = document.getElementById('ip-input-error-field');
          var ipSuggestionsTable = document.getElementById('ip-suggestions-table');
        
          // Listeners to Change in IP
          var ipChangeListeners = [];
          var registerIpChangeListener = function(func, immediatelyInvoke) {
            if(immediatelyInvoke) {
              func.call(null, currentIp);
            }
            ipChangeListeners.push(func);
          };
          var unregisterIpChangeListener = function(func) {
            var i = ipChangeListeners.length;
            while(--i > -1) {
              if(ipChangeListeners[i] === func) {
                ipChangeListeners.splice(i, 1);
                break;
              }
            }
          };
          var notifyIpChangeListeners = function(newValue) {
            var i = ipChangeListeners.length;
            while(--i > -1) {
              ipChangeListeners[i].call(null, newValue);
            }
          };
          window.r5pro_registerIpChangeListener = registerIpChangeListener;
          window.r5pro_unregisterIpChangeListener = unregisterIpChangeListener;
        
          var normalizeIp = function(value) {
            var isValid = value !== null;
            isValid = isValid && value !== undefined;
            isValid = isValid && value !== "null";
            isValid = isValid && value !== "undefined";
            return isValid ? value : null;
          };
          var fillInIpSuggestions = function(currentIp) {
            var items = [];
            var localIp = normalizeIp("<%= localIp %>");
            var addIpToList = function(value) {
              if(value !== null && currentIp !== value) {
              items.push('<tr>' +
                  '<td>' +
                    '<a class="red-text ip-suggestion-link" href="#">' +
                      value +
                    '</a>' +
                  '</td>' +
                '</tr>');
              }
            };
            addIpToList(localIp);
            if (localIp !== hostname) {
              addIpToList(hostname);
            }
            if(items.length > 0) {
              ipSuggestionsTable.innerHTML = items.join('');
            }
          }
          var updateAndStoreUserEnteredIpAddress = function(value) {
            var expiry = 60*60*24;
            if(ipAddressField.hasOwnProperty('innerText')) {
              ipAddressField.innerText = value;
            }
            else {
              ipAddressField.textContent = value;
            }
            document.cookie = '<%= cookieName %>=' + value + '; path=/; max-age=' + expiry;
            currentIp = value;
            notifyIpChangeListeners(value);
            // update URL + query params
            var params = '<%= kvUrlParams %>'.split(';');
            var i = params.length;
            while (--i > -1) {
              var kv = params[i].split('=');
              if (kv[0] === 'host') {
                params[i] = 'host=' + value;
              }
              else if (kv[0] === '') {
                params.splice(i, 1);
              }
            }
            var query = params.length > 1 ? params.join('&') : params[0]
            window.location = [(window.location.origin + window.location.pathname), query].join('?');
          };
        
          var toggleOverlay = function(event) {
            event.preventDefault();
            event.stopPropagation();
            if(!isOverlayShown) {
              showOverlay();
            }
            else {
              hideOverlay();
            }
          };
          var showOverlay = function() {
            isOverlayShown = true;
            if(isIpAddressOverlayShown) {
               hideIpAddressOverlay();
            }
            ipOverlay.classList.remove('hidden');
          };
          var hideOverlay = function() {
            isOverlayShown = false;
            ipOverlay.classList.add('hidden');
          };
          var handleOverlayClose = function(event) {
            if(event.target !== githubLink &&
                event.target !== ipOverlayIpIncorrectButton) {
              event.stopPropagation();
              event.preventDefault();
              hideOverlay();
              return false;
            }
            else if(event.target === ipOverlayIpIncorrectButton) {
              toggleIpAddressOverlay(event);
            }
            return true;
          };
        
          var toggleIpAddressOverlay = function(event) {
            event.stopPropagation();
            event.preventDefault();
            if(!isIpAddressOverlayShown) {
              showIpAddressOverlay();
            }
            else {
              hideIpAddressOverlay();
            }
            return false;
          };
          var showIpAddressOverlay = function() {
            isIpAddressOverlayShown = true;
            if(isOverlayShown) {
              hideOverlay();
            }
            ipAddressOverlay.classList.remove('hidden');
          };
          var hideIpAddressOverlay = function() {
            isIpAddressOverlayShown = false;
            ipAddressOverlay.classList.add('hidden');
            ipAddressErrorField.classList.add('hidden');
          };
          var handleIpAddressOverlayClose = function(event) {
            if(event.target !== ipAddressInput &&
                event.target !== ipAddressInputSubmit &&
                !event.target.classList.contains('ip-suggestion-link')) {
                event.preventDefault();
                event.stopPropagation();
                hideIpAddressOverlay();
                return false;
            }
            else if(event.target.classList.contains('ip-suggestion-link')) {
              var value;
              event.preventDefault();
              event.stopPropagation();
              hideIpAddressOverlay();
              if(event.target.hasOwnProperty('innerText')) {
                value = event.target.innerText;
              }
              else {
                value = event.target.textContent;
              }
              updateAndStoreUserEnteredIpAddress(value);
              return false;
            }
            return true;
          };
          var handleIpAddressInputSubmit = function(event) {
            var value = ipAddressInput.value;
            event.stopPropagation();
            event.preventDefault();
            ipAddressErrorField.classList.add('hidden');
            // Removing Regex check for now.
        //      if(validIpRegex.test(value)) {
              updateAndStoreUserEnteredIpAddress(value);
              hideIpAddressOverlay();
        //      }
        //      else {
        //        ipAddressErrorField.classList.remove('hidden');
        //      }
            return false;
          };
          ipOverlayButton.addEventListener('click', toggleOverlay);
          ipOverlay.addEventListener('mousedown', handleOverlayClose);
          ipOverlay.addEventListener('touchstart', handleOverlayClose);
          ipAddressCloseButton.addEventListener('click', handleOverlayClose);
        
          ipAddressInput.addEventListener('keyup', function(event) {
            if(event.keyCode === 13) {
              handleIpAddressInputSubmit(event);
            }
          });
          ipAddressInputSubmit.addEventListener('click', handleIpAddressInputSubmit);
          ipAddressOverlay.addEventListener('mousedown', handleIpAddressOverlayClose);
          ipAddressOverlay.addEventListener('touchstart', handleIpAddressOverlayClose);
        
          registerIpChangeListener(fillInIpSuggestions, true);
        
        }(this, document));
        
        </script>
        
      </div>
      <div id="server-version-field" class="small-font-size">
        <span class="black-text">Red5 Pro Server Version</span>&nbsp;&nbsp;<span class="red-text">6.2.0.b406-release</span>
      </div>
    </div>
    <div class="main-container">
      <div id="menu-section">
        <!-- view jsp_header to view variables used in this page -->
        <div class="menu-content">
          <ul class="menu-listing">
            <li><a class="red-text menu-listing-internal" href="/">Welcome</a></li>
            <li><a class="red-text menu-listing-internal" href="/live">Live Streaming</a></li>
              <ul class="menu-sublisting">
                <li><a class="menu-broadcast-link red-text menu-listing-nested" href="/live/broadcast.jsp?host=<%= ip %>">Broadcast</a></li>
                <li><a class="red-text menu-listing-nested" href="/live/subscribe.jsp?host=<%= ip %>">Subscribe</a></li>
                <li><a class="red-text menu-listing-nested" href="/live/playback.jsp?host=<%= ip %>">VOD Playback</a></li>
        <!--         <li><a class="red-text menu-listing-nested" href="/live/twoway.jsp">Two-Way Streaming Example</a></li> -->
              </ul>
            <li><a class="red-text menu-listing-internal" href="/inspector">Red5 Pro Inspector</a></li><li><a class="red-text menu-listing-internal" href="/streammanager">Stream Manager</a></li><li><a class="red-text menu-listing-internal" href="/webrtcexamples">Red5 Pro HTML SDK Testbed</a></li>
          </ul>
          <hr>
          <ul class="menu-listing">
            <li><a class="red-text menu-listing-external" href="https://calendly.com/red5-pro/15-minute-phone-call" target="_blank">Let's Talk!</a></li>
            <li><a class="red-text menu-listing-external" href="https://red5pro.zendesk.com?origin=webapps" target="_blank">Found an Issue?</a></li>
          </ul>
          <script>
            (function(window, document) {
              var className = 'menu-broadcast-link';
              function handleLiveIpChange(value) {
                var elements = document.getElementsByClassName(className);
                var length = elements ? elements.length : 0;
                var index = 0;
                for(index = 0; index < length; index++) {
                  elements[index].href = ['/live/broadcast.jsp?host', value].join('=');
                }
              }
              window.r5pro_registerIpChangeListener(handleLiveIpChange);
             }(this, document));
          </script>
        </div>
      </div>
      <div id="content-section">
        <div id="subcontent-section">
          <div id="subcontent-section-text">
            <h1 class="red-text">RED5 PRO BASIC BANDWIDTH DETECTION</h1>
          </div>
        </div>
        <div class="content-section-story">
          <form class="form" action="javascript:" method="post">
            <div class="form-entry form--seconds">
              <label for="form--seconds-input">Bandwidth Check Seconds:</label>
              <input type="number" name="form--seconds-input" class="form--seconds-input" value="3">
            </div>
            <div class="form-entry form--timeout">
              <label for="form--timeout-input">Timeout Seconds:</label>
              <input type="number" name="form--timeout-input" class="form--timeout-input" value="1">
            </div>
            <div class="form--submit">
              <button type="submit" name="form--submit-btn" class="ui-button">Check Bandwidth</button>
            </div>
          </form>
          <div class="results-container">
            <p class="results-title">RESULTS</p>
            <div class="results">
              <p style="width: 100%; text-align:center;">Waiting for results...</p>
            </div>
          </div>
          <hr class="top-padded-rule">
          <div>
            <h2><a class="link" href="/webrtcexamples">Web-Based Examples</a></h2>
            <p>Our HTML SDK has full WebRTC support with failovers for Flash and HLS.</p>
            <p>Several examples are shipped with the Red5 Pro Server and are available to use and test at <a class="link" href="/webrtcexamples">/webrtexamples</a>.</p>
            <p><a class="link blue-text" target="_blank" href="https://github.com/red5pro/streaming-html5">View source on Github</a></p>
          </div>
          
          <hr class="top-padded-rule">
          <div>
            <h2 class="red-text">Mobile Examples</h2>
            <p>We fully support Android and iOS native applications. Our optimized SDKs increase the server capacity, saving you money on hosting costs.</p>
            <p>You can find the following Open Source native application examples on our <a class="link" href="https://github.com/red5pro" target="_blank">Github</a>:</p>
            <div class="menu-content" style="margin: 16px 0; padding: 10px 0;">
              <ul class="menu-listing application-listing">
                <li><a class="red-text" style="text-decoration: underline;" href="https://github.com/red5pro/streaming-ios" target="_blank">Red5 Pro iOS Examples</a></li>
                <li><a class="red-text" style="text-decoration: underline;" href="https://github.com/red5pro/streaming-android" target="_blank">Red5 Pro Android Examples</a></li>
              </ul>
            </div>
            <p>Follow the project setup and build instructions in each project to easily create Red5 Pro native clients to begin using the above server applications!</p>
          </div>
          
          <hr class="top-padded-rule">
          <div>
            <h2 class="red-text">API Documentation</h2>
            <p>To find more in-depth information about the Red5 Pro Server, the HTML SDK and Mobile SDKs, please visit <a class="link" target="_blank" href="https://www.red5pro.com/docs/">https://www.red5pro.com/docs/</a>.</p>
          </div>
          
        </div>
      </div>
    </div>
    <script src="index.js" charset="utf-8"></script>
  </body>
</html>
