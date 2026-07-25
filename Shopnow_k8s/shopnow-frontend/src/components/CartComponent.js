import React, { useState, useEffect } from "react";
import cartService from "../services/CartService";
import { ListGroup, Button } from "react-bootstrap";
import DeleteIcon from "@mui/icons-material/Delete";
import IconButton from "@mui/material/IconButton";
import { ShoppingCartRounded } from "@mui/icons-material";
import "bootstrap/dist/css/bootstrap.min.css";

const CartComponent = () => {
    const [cartProducts, setCartProducts] = useState([]);
    const [totalPrice, setTotalPrice] = useState(0);
    const [cartId, setCartId] = useState(null);

    useEffect(() => {
        const retrieveCart = async () => {
            const user = localStorage.getItem("user");
            const parsedUser = JSON.parse(user);

            try {
                const response = await cartService.getByName(parsedUser.username);
                setCartId(response.data.id);
                setCartProducts(response.data.products);
                fetchTotalPrice(response.data.id);
            } catch (e) {
                console.error("Failed to retrieve cart:", e);
            }
        };

        retrieveCart();
    }, []);

    const fetchTotalPrice = async (id) => {
        try {
            const response = await cartService.getTotalPrice(id);
            setTotalPrice(response.data.total_price);
        } catch (e) {
            console.error("Failed to fetch total price:", e);
        }
    };

    const removeProductFromCart = (product) => {
        cartService.deleteProduct(cartId, product.id)
            .then((response) => {
                const { products } = response.data;
                setCartProducts(products);
                fetchTotalPrice(cartId);
            })
            .catch((e) => {
                console.error("Failed to remove product from cart:", e);
            });
    };

    // Hàm định dạng tiền tệ theo chuẩn Việt Nam
    const formatCurrency = (amount) => {
        const number = Number(amount) || 0; // Đảm bảo giá trị luôn là số
        return number.toLocaleString("vi-VN");
    };

    return (
        <div className="cart-container">
            <h4 className="cart-title"><ShoppingCartRounded /> My Cart </h4>
            <ListGroup>
                {cartProducts &&
                    cartProducts.map((cartProduct, index) => (
                        <ListGroup.Item
                            key={index}
                            style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                            <span style={{ textTransform: "capitalize" }}>{cartProduct.name} </span>
                            <IconButton aria-label="delete" onClick={() => removeProductFromCart(cartProduct)} >
                                <DeleteIcon size="small" color="primary" />
                            </IconButton>
                        </ListGroup.Item>
                    ))}
                <div className="total-price-container" style={{ marginTop: "15px", fontWeight: "bold" }}>
                    <span>Total Price:</span>
                    <span className="total-price"> {formatCurrency(totalPrice)} VNĐ</span>
                </div>
            </ListGroup>
            <Button variant="primary" className="mt-3" style={{ backgroundColor: "#fd3318", width: "50%", margin: "20px auto 0", display: "block" }}>Thanh toán</Button>
        </div>
    );
};

export default CartComponent;
