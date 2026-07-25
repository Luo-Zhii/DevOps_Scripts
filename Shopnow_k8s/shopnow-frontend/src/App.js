import React, { Component } from "react";
import { Routes, Route, Link } from "react-router-dom";
import { Container, Navbar, Nav, Form, FormControl, Button } from "react-bootstrap";
import { Search, ShoppingCart, Notifications, Help, Language } from "@mui/icons-material";
import "bootstrap/dist/css/bootstrap.min.css";
import "./App.css";

import LoginComponent from "./components/LoginComponent";
import RegisterComponent from "./components/RegisterComponent";
import HomeComponent from "./components/HomeComponent";
import ProfileComponent from "./components/ProfileComponent";
import ProductsListComponent from "./components/ProductsListComponent";
import CartComponent from "./components/CartComponent";
import AddProductComponent from "./components/AddProductComponent";
import ProductEditComponent from "./components/ProductEditComponent";

import { logout } from "./actions/auth";
import { connect } from "react-redux";
import { clearMessage } from "./actions/message";
import { history } from './helpers/history';

import AuthVerify from "./common/AuthVerify";
import EventBus from "./common/EventBus";
import { Login, Logout, Person, PersonAdd } from "@mui/icons-material";
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import ProfileEditComponent from "./components/ProfileEditComponent";

class App extends Component {
  constructor(props) {
    super(props);
    this.logOut = this.logOut.bind(this);

    this.state = {
      currentUser: undefined,
    };

    history.listen((location) => {
      props.dispatch(clearMessage());
    });
  }

  componentDidMount() {
    const user = this.props.user;

    if (user) {
      this.setState({
        currentUser: user
      });
    }

    EventBus.on("logout", () => {
      this.logOut();
    });
  }

  componentWillUnmount() {
    EventBus.remove("logout");
  }

  logOut() {
    this.props.dispatch(logout());
    this.setState({
      currentUser: undefined,
    });
  }

  render() {
    const { currentUser } = this.state;

    // Style của shop now
    const appStyle = `
      body {
        margin: 0;
        font-family: Arial, sans-serif;
      }
      .header-container {
        top: 0;
        position: sticky;
        z-index: 1000;
      }
      .header-top {
        display: flex;
        justify-content: space-between;
        align-items: center;
        background-color: #fd3318;
        color: #fff;
        font-size: 14px;
        padding: 5px 20px;

      }
      .header-top a {
        color: #fff;
        text-decoration: none;
        margin-left: 10px;
      }
      .header-top a:hover {
        text-decoration: underline;
      }
      .navbar {
        background-color: #fd3318;
        padding: 20px 20px;
        top: 1;
        position: sticky;
        z-index: 1000;
      }
      .search-form {
        display: flex;
        width: 600px;
      }
      .search-form input {
        flex: 1;
        border: none;
        padding: 8px 10px;
      }
      .search-button {
        background-color: #fb6445;
        border: none;
        padding: 0 15px;
      }
      .search-button svg {
        color: white;
      }
      .nav-icons a {
        color: white;
        margin-left: 15px;
      }
      .auth-links a {
        color: white;
        margin-left: 10px;
      }
    `;

    return (
      <>
        {/* Inject CSS */}
        <style>{appStyle}</style>
        <div class="header-container">
        {/* Header Top */}
        <div className="header-top">
          <div>
            <a href="https://devopsedu.vn/" target="_blank">Kênh bản quyền</a>
            <a href="https://devopsedu.vn/contact/" target="_blank">Trở thành người đóng góp</a>
            <a href="https://devopsedu.vn/blog/" target="_blank">Tài liệu tham khảo</a>
            <a href="https://m.me/139689492555066" target="_blank">Liên hệ</a>
          </div>
          <div>
            <a href="#"><Notifications /></a>
            <a href="#"><Help /></a>
            <a href="#"><Language /> Tiếng Việt</a>
            {currentUser ? (
              <>
                <Link to="/profile" className="auth-links">{currentUser.username}</Link>
                <a href="#" className="auth-links" onClick={this.logOut}>Đăng Xuất</a>
              </>
            ) : (
              <>
                <Link to="/register" className="auth-links">Đăng Ký</Link>
                <Link to="/login" className="auth-links">Đăng Nhập</Link>
              </>
            )}
          </div>
        </div>

        {/* Navbar */}
        <Navbar expand="lg" className="navbar" variant="dark">
          <Container fluid>
            {/* Logo */}
            <Navbar.Brand as={Link} to="/">
              <img
                src="/Shop now-logo.png"
                alt="Logo"
                width="120"
                height="40"
              />
            </Navbar.Brand>

            {/* Thanh tìm kiếm */}
            <Form className="search-form">
              <FormControl
                type="search"
                placeholder="Shop now bao ship 0đ - Đăng ký ngay!"
                aria-label="Search"
              />
              <Button className="search-button">
                <Search />
              </Button>
            </Form>

            {/* Biểu tượng giỏ hàng */}
            <div className="nav-icons">
              <a href="/cart">
                  <ShoppingCart />
              </a>
            </div>
          </Container>
        </Navbar>
        </div>

        {/* Nội dung trang */}
        <div className="container mt-3">
          <Routes>
            <Route path="/" element={<HomeComponent />} />
            <Route path="/login" element={<LoginComponent />} />
            <Route path="/register" element={<RegisterComponent />} />
            <Route path="/cart" element={<CartComponent />} />
            {currentUser && (
              <>
                <Route path="/profile" element={<ProfileComponent />} />
                <Route path="/profile/:id" element={<ProfileEditComponent />} />
                <Route path="/products" element={<ProductsListComponent />} />
                <Route path="/products/add" element={<AddProductComponent />} />
                <Route path="/products/:id" element={<ProductEditComponent />} />
              </>
            )}
          </Routes>
        </div>
        <ToastContainer />
        <AuthVerify logOut={this.logOut} />
      </>
    );
  }
}

function mapStateToProps(state) {
  const { user } = state.auth;
  return {
    user,
  };
}

export default connect(mapStateToProps)(App);
