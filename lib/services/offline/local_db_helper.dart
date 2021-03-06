import 'package:flutter/material.dart';
import 'package:shopping/model/product_model.dart';
import 'package:shopping/model/sales_item_model.dart';
import 'package:shopping/model/sales_model.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DBHelper {
  /// Table Creation
  // creating products table
  static const String myProductsTable = "CREATE TABLE IF NOT EXISTS products(" +
      "id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," +
      "name	TEXT NOT NULL," +
      "slug	TEXT NOT NULL," +
      "description	TEXT DEFAULT NULL," +
      "image TEXT DEFAULT NULL," +
      "price INTEGER NOT NULL," +
      "in_stock INTEGER NOT NULL DEFAULT 0," +
      "qty_per_order INTEGER NOT NULL DEFAULT 0," +
      "is_active INTEGER NOT NULL DEFAULT 1," +
      "created_at TEXT DEFAULT NULL," +
      "updated_at TEXT DEFAULT NULL," +
      "is_sync INTEGER NOT NULL DEFAULT 0" +
      ")";

  // creating sales table
  static const String mySalesTable = "CREATE TABLE IF NOT EXISTS sales(" +
      "id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," +
      "order_no	TEXT NOT NULL," +
      "ordered_at	TEXT NOT NULL," +
      "total REAL DEFAULT NULL," +
      "created_at TEXT DEFAULT NULL," +
      "updated_at TEXT DEFAULT NULL," +
      "is_sync INTEGER NOT NULL DEFAULT 0" +
      ")";

  // creating sale item table
  static const String mySalesItemTable =
      "CREATE TABLE IF NOT EXISTS sales_item(" +
          "id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," +
          "sale_id	INTEGER NOT NULL," +
          "product_id	INTEGER NOT NULL," +
          "unit_price	REAL NOT NULL," +
          "quantity INTEGER NOT NULL," +
          "total REAL NOT NULL," +
          "created_at TEXT DEFAULT NULL," +
          "updated_at TEXT DEFAULT NULL," +
          "is_sync INTEGER NOT NULL DEFAULT 0" +
          ")";

  /// Opening database
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return await sql.openDatabase(
      path.join(dbPath, "shopping.db"),
      onCreate: (db, version) {
        db.execute(myProductsTable);
        db.execute(mySalesTable);
        db.execute(mySalesItemTable);
      },
      version: 1,
    );
  }

  /// Products Table Beginning

  // insert values to products table
  static Future<int> insertValuesToProductsTable(
      Map<String, dynamic> data) async {
    int result = 0;
    final db = await DBHelper.database();

    debugPrint('RECORD IS ADDED PRODUCTS TABLE:  $data');

    result = await db.insert('products', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    print('RECORD IS ADDED TO PRODUCTS TABLE:  $result');
    return result;
  }

  // get all records form products table
  static Future<List<ProductsModel>> getProductsList() async {
    final db = await DBHelper.database();
    var res = await db.query("products");
    print('SHOW PRODUCTS TABLE OFFLINE RECORDS: $res');
    print('SHOW PRODUCTS TABLE OFFLINE RECORDS: ${res.length}');
    List<ProductsModel> list =
        res.isNotEmpty ? res.map((c) => ProductsModel.fromMap(c)).toList() : [];
    return list;
  }

  // getting particular product detail by id
  static Future<List<ProductsModel>> getParticularProductDetails(int id) async {
    final db = await DBHelper.database();
    var res = await db.query("products", where: 'id = ?', whereArgs: [id]);
    List<ProductsModel> list =
        res.isNotEmpty ? res.map((c) => ProductsModel.fromMap(c)).toList() : [];
    return list;
  }

  // getting particular product detail in offline by is_sync value equal to 0
  static Future<List<ProductsModel>> getParticularProductsInOffline(
      int isSync) async {
    final db = await DBHelper.database();
    var res =
        await db.query("products", where: 'is_sync = ?', whereArgs: [isSync]);
    List<ProductsModel> list =
        res.isNotEmpty ? res.map((c) => ProductsModel.fromMap(c)).toList() : [];
    return list;
  }

  // to update a field in a table
  static Future<void> updateProductsTableSyncStatus(int value, int id) async {
    final db = await DBHelper.database();
    await db.rawUpdate(
      "UPDATE products SET is_sync = '$value' WHERE id = '$id' ",
    );
  }

  /// Sales Table Beginning
  // Insert values to sales table
  static Future<int> insertValuesToSalesTable(Map<String, dynamic> data) async {
    int result = 0;
    final db = await DBHelper.database();
    result = await db.insert('sales', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    debugPrint('RECORD IS ADDED SALES TABLE:  $result');
    return result;
  }

  // get all records form sales table
  static Future<List<SalesModel>> getSalesList() async {
    final db = await DBHelper.database();
    var res = await db.query("sales");
    List<SalesModel> list =
        res.isNotEmpty ? res.map((c) => SalesModel.fromMap(c)).toList() : [];
    return list;
  }

  // to update a field in a table
  static Future<void> updateById(double value, String id) async {
    final db = await DBHelper.database();
    await db.rawUpdate(
      "UPDATE sales SET total = '$value' WHERE id = '$id' ",
    );
  }

  /// Sales Item Table Beginning
  // Insert values to sales item table
  static Future<int> insertValuesSalesItemTable(
      Map<String, dynamic> data) async {
    int result = 0;
    final db = await DBHelper.database();
    var maxIdResult =
        await db.rawQuery("SELECT MAX(id) as last_inserted_id FROM sales");
    var id = maxIdResult.first["last_inserted_id"];
    debugPrint('SHOW LAST ADDED SALES ID: $id');

    data['sale_id'] = id;

    result = await db.insert('sales_item', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);

    updateById(data['total'], id.toString());
    debugPrint('RECORD IS ADDED SALES ITEM TABLE:  $result');
    return result;
  }

  // get all records from sales item table
  static Future<List<SalesItemModel>> getSalesItemList() async {
    final db = await DBHelper.database();
    var res = await db.query("sales_item");
    List<SalesItemModel> list = res.isNotEmpty
        ? res.map((c) => SalesItemModel.fromMap(c)).toList()
        : [];
    return list;
  }

  // getting particular product detail in offline by is_sync value equal to 0
  static Future<List<SalesItemModel>> getParticularSalesItemsInOffline(
      int isSync) async {
    final db = await DBHelper.database();
    var res =
        await db.query("sales_item", where: 'is_sync = ?', whereArgs: [isSync]);
    debugPrint('SHOW SALES ITEM TABLE RECORDS IN OFFLINE:  $res');
    List<SalesItemModel> list = res.isNotEmpty
        ? res.map((c) => SalesItemModel.fromMap(c)).toList()
        : [];
    return list;
  }

  // check particular product detail in is already added or not
  static Future<List<SalesItemModel>> getParticularSalesItemAddedOrNot(
      int id) async {
    final db = await DBHelper.database();
    var res =
        await db.query("sales_item", where: 'product_id = ?', whereArgs: [id]);
    debugPrint('SHOW SALES ITEM TABLE RECORDS IN OFFLINE:  $res');
    List<SalesItemModel> list = res.isNotEmpty
        ? res.map((c) => SalesItemModel.fromMap(c)).toList()
        : [];
    return list;
  }

  // get sum of total in sales item table
  static Future getTotal() async {
    final db = await DBHelper.database();
    var result =
        await db.rawQuery("SELECT SUM(total) as Total FROM sales_item");
    return result[0]['Total'];
  }

  static Future getSalesItemTableSelectedFields() async {
    final db = await DBHelper.database();
    var maps = await db.rawQuery(
        "SELECT product_id,unit_price,quantity,total FROM sales_item");
    debugPrint('SHOW SELECTED VALUES FROM THE LIST: $maps');
    return maps.toList();
  }

  // delete a record a sales item table by specific id
  static Future<int> deleteSalesItem(int productId) async {
    final db = await DBHelper.database();
    return await db
        .delete("sales_item", where: 'product_id = ?', whereArgs: [productId]);
  }

  static close() async {
    final db = await DBHelper.database();
    db.close();
  }
}
