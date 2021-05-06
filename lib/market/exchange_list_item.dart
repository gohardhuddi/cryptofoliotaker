import 'package:flutter/material.dart';

import 'coin_exchange_stats.dart';
import '../landing.dart';

class ExchangeListItem extends StatelessWidget {
  ExchangeListItem(this.exchangeDataSnapshot, this.columnProps);
  final columnProps;
  final exchangeDataSnapshot;

  @override
  Widget build(BuildContext context) {
    return new InkWell(
        onTap: () {
          Navigator.of(context).push(new MaterialPageRoute(
              builder: (BuildContext context) => new CoinMarketStats(
                    exchangeData: exchangeDataSnapshot,
                    e: exchangeDataSnapshot["MARKET"],
                  )));
        },
        child: new Container(
          padding: const EdgeInsets.all(6.0),
          decoration: new BoxDecoration(),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Container(
                width: MediaQuery.of(context).size.width * columnProps[0],
                child: new Text(exchangeDataSnapshot["MARKET"],
                    style: Theme.of(context).textTheme.bodyText2),
              ),
              new Container(
                alignment: Alignment.centerRight,
                width: MediaQuery.of(context).size.width * columnProps[1],
                child: new Text(
                    "\$" + normalizeNum(exchangeDataSnapshot["VOLUME24HOURTO"]),
                    style: Theme.of(context).textTheme.bodyText2),
              ),
              new Container(
                width: MediaQuery.of(context).size.width * columnProps[2],
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    new Text("\$" +
                        normalizeNumNoCommas(exchangeDataSnapshot["PRICE"])),
                    exchangeDataSnapshot["CHANGEPCT24HOUR"] > 0
                        ? new Text(
                            "+" +
                                exchangeDataSnapshot["CHANGEPCT24HOUR"]
                                    .toStringAsFixed(2) +
                                "%",
                            style: Theme.of(context)
                                .textTheme
                                .bodyText2
                                .apply(color: Colors.green))
                        : new Text(
                            exchangeDataSnapshot["CHANGEPCT24HOUR"]
                                    .toStringAsFixed(2) +
                                "%",
                            style: Theme.of(context)
                                .textTheme
                                .bodyText2
                                .apply(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
