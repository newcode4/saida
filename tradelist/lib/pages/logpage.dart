import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tradelist/common/Constants.dart';
import 'package:tradelist/common/dialog.dart';
import 'package:tradelist/library/do_progress_bar.dart';
import 'package:tradelist/model/GetxController.dart';
import 'package:tradelist/model/item_model.dart';
import 'package:tradelist/pages/sellpage.dart';
import 'package:tradelist/utilites/toolsUtilities.dart';

LogPageState pageState;

class LogPage extends StatefulWidget {
  @override
  LogPageState createState() {
    pageState = LogPageState();
    return pageState;
  }
}

class LogPageState extends State<LogPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // 컬렉션명
  final String buyName = "buy_data";
  final String sellName = "sell_data";

  bool Tabchange = false;

  // 필드명
  final String title = "title";
  final String buyPrice = "buyPrice";
  final String buyTotal = "buyTotal";
  final String buyVolume = "buyVolume";

  // final String buyDatetime = "buyDatetime";

  TextEditingController _newNameCon = TextEditingController();
  TextEditingController _newPriceCon = TextEditingController();
  TextEditingController _newSuCon = TextEditingController();

  TextEditingController _undNameCon = TextEditingController();
  TextEditingController _undPriceCon = TextEditingController();
  TextEditingController _undSuCon = TextEditingController();

  final controller = Get.put(BuilderController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text(
            '이용자 금액, 수익률 들어갈 예정',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.black,
            tabs: <Widget>[
              Tab(
                child: Text('진행종목', style: TextStyle(color: Colors.black)),
              ),
              Tab(
                child: Text('완료종목', style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
        body: ListView(
          children: <Widget>[
            Container(
                height: 500,
                child: StreamBuilder<QuerySnapshot>(
                    stream: Firestore.instance
                        .collection(buyName)
                    // .orderBy(buyDatetime, descending: true)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError)
                        return Text("Error: ${snapshot.error}");
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return Text("Loading...");
                        default:
                          return TabBarView(
                            children: <Widget>[
                              list_1(snapshot),
                              SellPage()
                            ],
                          );
                      }
                      // list_1(snapshot);
                    })),
          ],
        ),

        // Create Document
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: showCreateDocDialog,
          backgroundColor: ToolsUtilities.secondColor,
        ),
      ),
    );
  }

  ListView list_1(AsyncSnapshot<QuerySnapshot> snapshot) {
    Future<void> insertData(final product) async {
      Firestore firestore = Firestore.instance;

      firestore
          .collection(sellName)
          .add(product)
          .then((DocumentReference document) {
        print(document.documentID);
      }).catchError((e) {
        print(e);
      });
    }

    return ListView(
      children: snapshot.data.documents.map((DocumentSnapshot document) {
        // Timestamp ts = document[buyDatetime];
        // String dt = timestampToStrDateTime(ts);
        return Card(
            elevation: 4,
            margin: EdgeInsets.all(8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            color: Colors.white,
            child: InkWell(
              // Read Document
                onTap: () {
                  showDocument(document.documentID);
                },
                // Update or Delete Document
                onLongPress: () {
                  showUpdateOrDeleteDocDialog(document);
                },
                child: Container(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      trailing: Container(
                        width: 150,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              ButtonBar(
                                children: [
                                  RaisedButton(
                                    onPressed: () {
                                      final String bname = document[title];
                                      final String bprice = document[buyPrice];
                                      final String bvolume = document[buyVolume];
                                      final int data = int.parse(document[buyTotal]);

                                      controller.movedata(bvolume);

                                      final ItemBuyModel product = ItemBuyModel(
                                          title: bname,
                                          // buyDatetime: btime,
                                          buyPrice: bprice,
                                          buyVolume: bvolume);

                                      LogDiaLog(context, bname, bvolume,data);
                                    },
                                    child: const Text('매도하기'),
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                              IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    deleteDoc(document.documentID);
                                  }),
                            ]),
                      ),
                      title: Text(
                        document[title],
                        style: TextStyle(
                          fontSize: 16.5,
                          fontFamily: 'RobotoMono',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        "매수가 : ${document[buyPrice]}원"
                            "\n평가금액 : ${document[buyTotal]}원",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontFamily: 'RobotoMono',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ))));
      }).toList(),
    );
  }


  /// Firestore CRUD Logic

  // 문서 생성 (Create)
  void createDoc(String name, String price, String volume, String result) {
    Firestore.instance.collection(buyName).add({
      title: name,
      buyPrice: price,
      buyVolume: volume,
      buyTotal: result,
      // fnDatetime: Timestamp.now(),
    });
  }

  void createDoc2(String name, String price, String volume, String result) {
    Firestore.instance.collection(sellName).add({
      title: name,
      buyPrice: price,
      buyVolume: volume,
      buyTotal: result,
      // fnDatetime: Timestamp.now(),
    });
  }

  trans(String formatname) {
    NumberFormat('###,###,###,###').format(formatname).replaceAll(' ', '');
  }

  // 문서 조회 (Read)
  void showDocument(String documentID) {
    Firestore.instance
        .collection(buyName)
        .document(documentID)
        .get()
        .then((doc) {
      showReadDocSnackBar(doc);
    });
  }

  void showSellDocument(String documentID) {
    Firestore.instance
        .collection(sellName)
        .document(documentID)
        .get()
        .then((doc) {
      showReadDocSnackBar(doc);
    });
  }

  // 문서 갱신 (Update)
  void updateDoc(String docID, String name, String description) {
    Firestore.instance.collection(buyName).document(docID).updateData({
      title: name,
      buyPrice: docID,
      buyTotal: description,
    });
  }

  // 문서 삭제 (Delete)
  void deleteDoc(String docID) {
    Firestore.instance.collection(buyName).document(docID).delete();
  }

  void deleteSellDoc(String docID) {
    Firestore.instance.collection(sellName).document(docID).delete();
  }

  void showCreateDocDialog() {
    var result;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "종목 추가하기",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Container(
            height: 200,
            child: Column(
              children: <Widget>[
                TextFormField(
                  autofocus: true,
                  decoration: InputDecoration(labelText: "이름"),
                  controller: _newNameCon,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "매수가"),
                  keyboardType: TextInputType.number,
                  controller: _newPriceCon,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "수량"),
                  keyboardType: TextInputType.number,
                  controller: _newSuCon,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("취소"),
              onPressed: () {
                _newNameCon.clear();
                _newPriceCon.clear();
                _newSuCon.clear();
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text("생성"),
              onPressed: () {
                var value3 = int.parse(_newPriceCon.text);
                var value4 = int.parse(_newSuCon.text);
                result = value3 * value4;
                if (_newPriceCon.text.isNotEmpty &&
                    _newNameCon.text.isNotEmpty) {
                  createDoc(_newNameCon.text, _newPriceCon.text, _newSuCon.text,
                      result.toString());
                }
                _newNameCon.clear();
                _newPriceCon.clear();
                _newSuCon.clear();
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  void showReadDocSnackBar(DocumentSnapshot doc) {
    var scaffoldState = _scaffoldKey.currentState
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: ToolsUtilities.whiteColor,
          duration: Duration(seconds: 5),
          content: Text(
            "${doc[title]}\n\n"
                "거래 로그 적을 예정",
            style: TextStyle(color: Colors.black),
          ),
          // "\n$buyDatetime: ${timestampToStrDateTime(doc[buyDatetime])}"),
          action: SnackBarAction(
            label: "닫기",
            textColor: Colors.blue,
            onPressed: () {},
          ),
        ),
      );
  }

  void showUpdateOrDeleteDocDialog(DocumentSnapshot doc) {
    _undNameCon.text = doc[title];
    _undPriceCon.text = doc[buyPrice];
    _undSuCon.text = doc[buyTotal];
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("수정 / 삭제"),
          content: Container(
            height: 200,
            child: Column(
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(labelText: "이름"),
                  controller: _undNameCon,
                ),
                TextField(
                  decoration: InputDecoration(labelText: "매수가"),
                  controller: _undPriceCon,
                ),
                TextField(
                  decoration: InputDecoration(labelText: "수량"),
                  controller: _undPriceCon,
                )
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("취소"),
              onPressed: () {
                _undNameCon.clear();
                _undPriceCon.clear();
                _undSuCon.clear();
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text("갱신"),
              onPressed: () {
                if (_undNameCon.text.isNotEmpty &&
                    _undPriceCon.text.isNotEmpty) {
                  updateDoc(
                      doc.documentID, _undNameCon.text, _undPriceCon.text);
                }
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text("삭제"),
              onPressed: () {
                deleteDoc(doc.documentID);
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  String timestampToStrDateTime(Timestamp ts) {
    return DateTime.fromMicrosecondsSinceEpoch(ts.microsecondsSinceEpoch)
        .toString();
  }
}
