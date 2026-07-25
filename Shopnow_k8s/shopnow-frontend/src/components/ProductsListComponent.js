import React, { useState, useEffect } from "react";
import productService from "../services/ProductService";
import { Link } from "react-router-dom";
import { connect } from "react-redux";
import { withRouter } from '../common/WithRouter';
import { updateProduct } from "../actions/products";
import { Card, ListGroup, Modal } from "react-bootstrap";
import cartService from "../services/CartService";
import DeleteIcon from '@mui/icons-material/Delete';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import { Add, Inventory2Sharp, ShoppingCartRounded } from "@mui/icons-material";
import { toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const ProductsList = () => {
    const [products, setProducts] = useState([]);
    const [cartProducts, setCartProducts] = useState([]);
    const [currentProduct, setCurrentProduct] = useState(null);
    const [totalPrice, setTotalPrice] = useState("");
    const [cartId, setCartId] = useState(null);
    const [showModal, setShowModal] = useState(false);

    const [isAdmin, setIsAdmin] = useState(false); // State để kiểm tra quyền admin

    useEffect(() => {
        // Kiểm tra nếu người dùng là admin
        const user = localStorage.getItem("user");
        if (user) {
            const parsedUser = JSON.parse(user);
            setIsAdmin(parsedUser.username === "admin");
        }
    }, []);

    const handleCloseModal = () => setShowModal(false);
    const handleShowModal = () => setShowModal(true);

    const retrieveCart = async () => {
        const user = localStorage.getItem("user");
        const parsedUser = JSON.parse(user);

        var isCartExist = false;
        try {
            const response = await cartService.getByName(parsedUser.username);
            setCartId(response.data.id);
            isCartExist = true;
            setCartProducts(response.data.products);
            getTotalPrice(response.data.id);
        } catch (e) {
            console.log(e);
        }

        if (!isCartExist) {
            cartService.create(parsedUser.username)
                .then((response) => {
                    setCartId(response.data.id);

                    console.log(response.data);
                })
                .catch((e) => {
                    console.log(e);
                });
        }

    };

    const retrieveProducts = () => {
        productService.getAll()
            .then((response) => {
                setProducts(response.data);

                console.log(response.data);
            })
            .catch((e) => {
                console.log(e);
            });
    };

    // eslint-disable-next-line react-hooks/exhaustive-deps
    useEffect(retrieveProducts, []);
    useEffect(() => {
        retrieveCart();
    }, []);

    const refreshList = () => {
        retrieveCart();
        retrieveProducts();
        setCurrentProduct(null);
    };

    const setActiveProduct = (product, index) => {
        setCurrentProduct(product);
        handleShowModal();
    };

    const deleteAllProducts = () => {
        const isConfirmed = window.confirm("Are you sure you want to delete all products?");

        if (!isConfirmed) {
            return;
        }

        productService.deleteAll()
            .then((response) => {
                console.log(response.data);
                refreshList();
                toast("All products deleted");
            })
            .catch((e) => {
                console.log(e);
            });
    };

    const deleteProduct = (product) => {
        productService.delete(product.id)
            .then((response) => {
                console.log(response.data);
                refreshList();
                toast(product.name + " deleted");
            })
            .catch((e) => {
                console.log(e);
            });
        handleCloseModal();
    };

    const addToCart = (product) => {
        cartService.addProducts(cartId, [product])
            .then((response) => {
                const { products } = response.data;
                setCartProducts(products);
                console.log(response.data);
                getTotalPrice(cartId);
                toast(product.name + " added to cart");
            })
            .catch((e) => {
                console.log(e);
            });
        handleCloseModal();
    };

    const removeProductFromCart = (product) => {
        cartService.deleteProduct(cartId, product.id)
            .then((response) => {
                const { products } = response.data;
                setCartProducts(products);
                console.log(response.data);
                getTotalPrice(cartId);
            })
            .catch((e) => {
                console.log(e);
            });
    };

    const getTotalPrice = (cartId) => {
        cartService.getTotalPrice(cartId)
            .then((response) => {
                setTotalPrice(response.data.total_price)
                console.log(response.data);
            })
            .catch((e) => {
                console.log(e);
            });
    };

    const productImageMap = {
        "Áo len ren màu hồng cardigan nữ": "ao-len-nu.png",
        "Điện thoại Apple iPhone 15 Pro Max 256GB": "iphone-15-promax.png",
        "Nike Air Jordan 1 Mid Chicago Toe Like Auth": "giay-nike-air.png",
        "MacBook Pro 14 inch M4 2024": "macbook-m4-pro.png",
        "Tai nghe Sony WH-1000XM4": "sony-wh-1000xm4.png",
        "Bàn phím cơ Razer": "ban-phim-co-razer.png",
        "Chuột Logitech G502": "chuot-logitech-g502.png",
        "Tivi LG OLED": "tivi-lg-oled.png",
        "Máy giặt Electrolux": "may-giat-electrolux.png",
        "Quạt điều hòa Sunhouse": "quat-dieu-hoa-sunhouse.png"
    };

    const formatCurrency = (amount) => {
        const number = Number(amount) || 0;
        return number.toLocaleString("vi-VN");
    };

    return (
        <div className="row justify-content-md-center">

            <Modal show={showModal} onHide={handleCloseModal}>
                <Modal.Header closeButton>
                    <Modal.Title>Product Details</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <Card style={{ marginTop: 0 }}>
                        <Card.Header><strong>Id:</strong> {currentProduct?.id}</Card.Header>
                        <Card.Body >
                            <Card.Title></Card.Title>
                            <Card.Text>
                                <div>
                                    <label>
                                        <strong>Name:</strong>
                                    </label>{" "}
                                    {currentProduct?.name}
                                    <label>
                                        <strong>Description:</strong>
                                    </label>{" "}
                                    {currentProduct?.description}
                                    <label>
                                        <strong>Category:</strong>
                                    </label>{" "}
                                    {currentProduct?.category}
                                    <label>
                                        <strong>Price:</strong>
                                    </label>{" "}
                                    {currentProduct?.price}
                                </div>
                            </Card.Text>
                            <div style={{ display: 'flex', justifyContent: 'center' }}>
                                <Link to={"/products/" + currentProduct?.id}>
                                    <Button className="m-3" variant="outlined" color="primary" onClick={() => updateProduct(currentProduct)} style={{ textTransform: "none", margin: '5px' }}>Edit</Button>
                                </Link>
                                <Button startIcon={<DeleteIcon />} className="m-3" variant="outlined" color="error" onClick={() => deleteProduct(currentProduct)} style={{ textTransform: "none", margin: '5px' }}>Delete</Button>
                                <Button startIcon={<ShoppingCartRounded />} className="m-3" variant="contained" onClick={() => addToCart(currentProduct)} style={{ textTransform: "none", margin: '5px' }}>Add to Cart</Button>
                            </div>
                        </Card.Body>
                    </Card>
                </Modal.Body>
                <Modal.Footer>
                    <Button variant="secondary" onClick={handleCloseModal}>
                        Close
                    </Button>
                </Modal.Footer>
            </Modal>

            <div className="col-md-12">
                <h4><Inventory2Sharp /> Products </h4>
                <div className="col-md-12 d-flex align-items-center justify-content-start">
                    {isAdmin && (
                        <>
                            <Button startIcon={<DeleteIcon />} className="" variant="outlined" color="error" onClick={deleteAllProducts} style={{ textTransform: "none" }}>Delete All</Button>
                            <Link to={"/products/add"}><Button startIcon={<Add />} className="m-3" variant="outlined" color="primary" style={{ textTransform: "none" }}>Add New</Button></Link>
                        </>
                    )}
                </div>
                <hr className="styled-hr" />
                <div className="row row-cols-1 row-cols-md-4 g-4">
                    {products &&
                        products.map((product, index) => (
                            <div key={index} className="col">
                                <Card className="product-card">
                                    <Card.Img 
                                        variant="top" 
                                        src={`/${productImageMap[product.name] || "placeholder.png"}`}
                                        onClick={() => setActiveProduct(product, index)} 
                                    />
                                    <Card.Body>
                                        <Card.Title style={{ textTransform: 'capitalize' }}>
                                            {product.name}
                                        </Card.Title>
                                        <Card.Subtitle className="mb-2 text-muted">
                                            {product.category}
                                        </Card.Subtitle>
                                        <Card.Text>
                                            {product.description.length > 66 
                                                ? product.description.substring(0, 66) + "..." 
                                                : product.description}
                                        </Card.Text>
                                        <Card.Text style={{ color: 'red' }}>
                                            {formatCurrency(product.price)} VNĐ
                                        </Card.Text>
                                        {currentProduct?.price}
                                        <div style={{ display: "flex", justifyContent: "space-between" }}>
                                            <Button
                                                startIcon={<ShoppingCartRounded />}
                                                variant="outlined"
                                                color="success"
                                                size="small"
                                                onClick={() => addToCart(product)}
                                                style={{ textTransform: "none" }}
                                            >
                                                Add to Cart
                                            </Button>
                                        </div>
                                    </Card.Body>
                                </Card>
                            </div>
                        ))}
                </div>
            </div>
        </div>
    );
};

export default connect(null,)(withRouter(ProductsList));
