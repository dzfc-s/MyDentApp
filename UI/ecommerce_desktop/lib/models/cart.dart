import 'package:MyDent_desktop/models/product.dart';

class Cart {
  List<CartItem> items = [];

}

class CartItem {
  late Product product;
  late int quantity;
}