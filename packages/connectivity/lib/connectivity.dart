// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

/// Connection Status Check Result
///
/// WiFi: Device connected via Wi-Fi
/// Mobile: Device connected to cellular network
/// None: Device not connected to any network
enum ConnectivityResult { wifi, mobile, none }

/// Describes a wifi network in range
///
/// BSSID : bssid of the network
/// SSID : ssid of the network
class WifiNetworkInfo {
  String BSSID, SSID;

  WifiNetworkInfo({this.BSSID, this.SSID});
}

const MethodChannel _methodChannel =
    MethodChannel('plugins.flutter.io/connectivity');

const EventChannel _eventChannel =
    EventChannel('plugins.flutter.io/connectivity_status');

class Connectivity {
  Stream<ConnectivityResult> _onConnectivityChanged;

  /// Fires whenever the connectivity state changes.
  Stream<ConnectivityResult> get onConnectivityChanged {
    if (_onConnectivityChanged == null) {
      _onConnectivityChanged = _eventChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseConnectivityResult(event));
    }
    return _onConnectivityChanged;
  }

  /// Checks the connection status of the device.
  ///
  /// Do not use the result of this function to decide whether you can reliably
  /// make a network request. It only gives you the radio status.
  ///
  /// Instead listen for connectivity changes via [onConnectivityChanged] stream.
  Future<ConnectivityResult> checkConnectivity() async {
    final String result = await _methodChannel.invokeMethod('check');
    return _parseConnectivityResult(result);
  }

  /// Obtains the wifi name (SSID) of the connected network
  ///
  /// Please note that it DOESN'T WORK on emulators (returns null).
  ///
  /// From android 8.0 onwards the GPS must be ON (high accuracy)
  /// in order to be able to obtain the SSID.
  Future<String> getWifiName() async {
    String wifiName = await _methodChannel.invokeMethod('wifiName');
    // as Android might return <unknown ssid>, uniforming result
    // our iOS implementation will return null
    if (wifiName == '<unknown ssid>') wifiName = null;
    return wifiName;
  }

  /// Obtains the wifi list (SSID,BSSID) of the visible networks
  ///
  /// From android 8.0 onwards the GPS must be ON (high accuracy)
  /// in order to be able to obtain the SSID.
  Future<List<WifiNetworkInfo>> getWifiNetworkList() async {
    final List<Map<dynamic, dynamic>> networkListMap =
        await _methodChannel.invokeMethod('wifiNetworkList');

    return networkListMap.map((n) {
      return WifiNetworkInfo(BSSID: n["bssid"], SSID: n["ssid"]);
    }).toList();
  }
}

ConnectivityResult _parseConnectivityResult(String state) {
  switch (state) {
    case 'wifi':
      return ConnectivityResult.wifi;
    case 'mobile':
      return ConnectivityResult.mobile;
    case 'none':
    default:
      return ConnectivityResult.none;
  }
}
