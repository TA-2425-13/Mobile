import 'dart:convert';

import 'package:app/global_var.dart';
import 'package:app/model/trade.dart';
import 'package:app/model/user_trade.dart';
import 'package:http/http.dart' as http;
import 'api_cache_service.dart';

class TradeService {
  static Future<List<TradeModel>> getAllTrades() async {
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/trade'));
      final body = response.body;
      final result = jsonDecode(body);
      List<TradeModel> trades = List<TradeModel>.from(
        result.map(
            (result) => TradeModel.fromJson(result)
        ),
      );
      return trades;
    } catch(e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> createUserTrade(int userId, int tradeId, int badgeId) async {
    try {
      Map<String, dynamic> request = {
        "userId": userId,
        "tradeId": tradeId
      };
      final response = await http.post(Uri.parse('${GlobalVar.baseUrl}/usertrade'), headers: {
        'Content-type' : 'application/json; charset=utf-8',
        'Accept': 'application/json',
      } , body: jsonEncode(request));

      final body = response.body;
      final result = jsonDecode(body);
      print(result['message']);
    } catch(e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<UserTrade>> getUserTrade(int userId) async{
    try {
      List<UserTrade> filteredUserTrade = [];
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/usertrade'));
      final body = response.body;
      final result = jsonDecode(body);
      List<UserTrade> trades = List<UserTrade>.from(
        result.map(
                (result) => UserTrade.fromJson(result)
        ),
      );
      for(UserTrade ut in trades){
        if(ut.userId == userId) {
          filteredUserTrade.add(ut);
        }
      }
      return filteredUserTrade;
    } catch(e) {
      throw Exception(e.toString());
    }
  }
}