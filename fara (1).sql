-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 29, 2025 at 04:19 PM
-- Server version: 10.4.14-MariaDB
-- PHP Version: 7.2.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `fara`
--

-- --------------------------------------------------------

--
-- Table structure for table `cart`
--

CREATE TABLE `cart` (
  `cart_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `size` varchar(50) DEFAULT NULL,
  `color` varchar(50) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `cart`
--

INSERT INTO `cart` (`cart_id`, `user_id`, `product_id`, `quantity`, `size`, `color`, `price`, `image_path`, `created_at`, `updated_at`) VALUES
(122, 84, 3, 1, 'Small', 'Black', '359.00', 'uploads/c6a3bf24-f674-406c-a270-fd69d96ab518.jpg', '2025-05-21 21:56:16', '2025-05-22 01:03:01'),
(123, 84, 3, 8, 'Small', 'Black', '359.00', 'uploads/c6a3bf24-f674-406c-a270-fd69d96ab518.jpg', '2025-05-21 21:56:18', '2025-05-21 22:22:06');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `category_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`category_id`, `name`, `description`) VALUES
(1, 'Suits & Blazers', NULL),
(2, 'Casual Shirts & Pants', NULL),
(3, 'Outerwear & Jackets', NULL),
(4, 'Activewear & Fitness Gear', NULL),
(5, 'Shoes & Accessorie', NULL),
(6, 'Grooming Products', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `message_id` int(11) NOT NULL,
  `sender_id` int(11) NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`message_id`, `sender_id`, `receiver_id`, `message`, `timestamp`) VALUES
(1, 107, 5, 'Hey', '2024-11-29 13:36:57'),
(4, 5, 107, 'hello', '2024-11-29 14:23:12'),
(5, 84, 5, 'yo bro', '2024-11-29 14:45:47'),
(6, 5, 84, 'Good Day!', '2024-11-29 15:07:03'),
(7, 5, 84, 'Any problem with our products?', '2024-11-29 15:22:37'),
(8, 107, 4, 'Good evening', '2024-11-29 15:26:39'),
(9, 81, 5, 'Ang pangit ng tela promise close my hearts!', '2024-11-30 05:13:53'),
(10, 5, 81, 'Sorry po cute ko e', '2024-11-30 05:14:41'),
(11, 81, 5, 'manahimik ka ', '2024-11-30 05:15:15'),
(12, 5, 81, 'pogi ba ako?\r\n', '2024-11-30 08:16:07'),
(13, 5, 81, 'HOY SAGOT', '2024-11-30 11:07:05'),
(14, 81, 5, 'kupal', '2024-11-30 11:41:33'),
(15, 5, 81, 'mas kupal ka', '2024-11-30 11:56:14'),
(16, 84, 5, 'no problem just me\r\n', '2024-11-30 15:58:40');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `shipping_id` int(11) DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `order_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `shipping_fee` decimal(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`order_id`, `user_id`, `shipping_id`, `total_amount`, `payment_method`, `order_date`, `shipping_fee`) VALUES
(40, 81, 128, '349.00', 'cod', '2024-11-30 08:03:31', '0.00'),
(41, 84, 129, '359.00', 'cod', '2024-12-07 13:41:53', '0.00'),
(42, 84, 129, '359.00', 'cod', '2024-12-07 13:46:45', '0.00'),
(43, 84, 129, '359.00', 'cod', '2024-12-07 13:47:57', '0.00'),
(44, 84, 129, '359.00', 'cod', '2024-12-07 13:55:55', '0.00'),
(45, 84, 129, '359.00', 'cod', '2024-12-07 14:01:22', '0.00'),
(46, 84, 129, '359.00', 'cod', '2024-12-07 14:06:10', '0.00'),
(47, 107, 152, '309.00', 'cod', '2025-02-23 07:45:24', '0.00'),
(48, 107, 152, '359.00', 'cod', '2025-04-14 15:30:39', '0.00'),
(49, 107, 152, '368.00', 'cod', '2025-05-16 16:20:42', '59.00'),
(50, 107, 152, '777.00', 'cod', '2025-05-16 16:22:36', '59.00'),
(51, 107, 152, '173.00', 'cod', '2025-05-18 21:15:15', '59.00'),
(52, 107, 152, '287.00', 'cod', '2025-05-18 22:23:47', '59.00'),
(53, 107, 152, '1035.00', 'cod', '2025-05-18 22:56:30', '59.00'),
(54, 84, 129, '247.00', 'cod', '2025-05-19 05:36:42', '59.00'),
(55, 84, 129, '547.00', 'cod', '2025-05-19 05:38:31', '59.00'),
(56, 84, 129, '547.00', 'cod', '2025-05-19 05:42:37', '59.00'),
(57, 84, 129, '158.00', 'cod', '2025-05-19 05:51:20', '59.00'),
(58, 84, 129, '508.00', 'cod', '2025-05-19 05:56:20', '59.00'),
(59, 84, 129, '247.00', 'cod', '2025-05-19 06:00:41', '59.00'),
(60, 107, 152, '247.00', 'cod', '2025-05-19 06:42:24', '59.00'),
(61, 84, 129, '798.00', 'cod', '2025-05-19 06:43:51', '59.00'),
(62, 107, 152, '439.00', 'cod', '2025-05-19 06:49:21', '59.00'),
(64, 84, 129, '418.00', 'cod', '2025-05-21 20:24:24', '59.00'),
(65, 84, 129, '348.00', 'cod', '2025-05-21 20:25:07', '59.00'),
(66, 84, NULL, '359.00', 'cod', '2025-05-21 21:06:42', '0.00'),
(67, 84, NULL, '449.00', 'cod', '2025-05-21 22:48:02', '0.00'),
(68, 84, NULL, '99.00', 'cod', '2025-05-22 01:14:14', '0.00'),
(69, 84, 129, '1523.00', 'cod', '2025-05-22 02:10:58', '59.00');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `order_item_id` int(11) NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `product_variation_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `size` varchar(50) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `order_status` varchar(50) DEFAULT 'Pending',
  `color` varchar(50) DEFAULT NULL,
  `rider_id` int(11) DEFAULT NULL,
  `shipping_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tracking_number` varchar(100) DEFAULT NULL,
  `delivery_proof` varchar(255) DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `status_changed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`order_item_id`, `order_id`, `product_id`, `product_variation_id`, `quantity`, `size`, `price`, `order_status`, `color`, `rider_id`, `shipping_fee`, `tracking_number`, `delivery_proof`, `delivered_at`, `status_changed_at`) VALUES
(38, 40, 18, 156, 1, 'L (61~65kg)', '349.00', 'Delivered', 'Navy Blue', NULL, '0.00', NULL, NULL, NULL, NULL),
(45, 47, 4, 120, 1, 'Extra Large', '309.00', 'Delivered', 'Grey', 4, '59.00', NULL, NULL, NULL, NULL),
(50, 51, 34, 217, 1, 'M', '114.00', 'Delivered', 'Red', 4, '59.00', 'TRK-34-1747602915', 'static/delivery_proofs\\proof_50_613f79b28b25403f9bcf4ae00acf6cc3.jpg', NULL, NULL),
(51, 52, 34, 219, 2, 'M', '114.00', 'Delivered', 'Black', 4, '59.00', 'TRK-34-1747607027', 'static/delivery_proofs\\proof_51_0776d427dd99431c9ecb985dae4581dd.jpg', NULL, NULL),
(52, 53, 35, 222, 2, '41', '488.00', 'Delivered', 'Black', 4, '59.00', 'TRK-35-1747608990', 'static/delivery_proofs\\proof_52_77cd4067e86f4ab295b504b5c29d7d5f.jpg', '2025-05-19 06:59:32', NULL),
(53, 54, 37, 232, 1, '42', '188.00', 'Pending', 'Brown', NULL, '59.00', 'TRK-37-1747633002', NULL, NULL, NULL),
(54, 55, 35, 223, 1, '40', '488.00', 'Pending', 'Coffee', NULL, '59.00', 'TRK-35-1747633111', NULL, NULL, NULL),
(55, 56, 35, 223, 1, '40', '488.00', 'Pending', 'Coffee', NULL, '59.00', 'TRK-35-1747633357', NULL, NULL, NULL),
(56, 57, 26, 183, 1, 'M', '99.00', 'Pending', 'Grey', NULL, '59.00', 'TRK-26-1747633880', NULL, NULL, NULL),
(57, 58, 6, 140, 1, '28', '449.00', 'Delivered', 'Black', 4, '59.00', 'TRK-6-1747634180', 'static/delivery_proofs\\proof_57_80d93993fa1f4502922b4f9155dc7f89.jpg', '2025-05-22 02:32:41', '2025-05-22 00:27:55'),
(58, 59, 37, 231, 1, '41', '188.00', 'Delivered', 'Brown', 4, '59.00', 'TRK-37-1747634441', 'static/delivery_proofs\\proof_58_d69ec977974f4dc1b5e456236d8cb94d.jpg', '2025-05-19 14:03:44', NULL),
(59, 60, 24, 176, 1, 'L', '188.00', 'Delivered', 'Maroon', 4, '59.00', 'TRK-24-1747636944', 'static/delivery_proofs\\proof_59_4037f956a2c945eb9253f54e0e09a466.jpg', '2025-05-19 14:43:27', NULL),
(60, 61, 20, 199, 1, 'Long 5 in 1', '739.00', 'Delivered', 'Black', 4, '59.00', 'TRK-20-1747637031', 'static/delivery_proofs\\proof_60_01ff3c099bc84df4801607d3f29f31f4.jpg', '2025-05-22 04:21:51', '2025-05-22 04:19:54'),
(61, 62, 23, 173, 1, 'L', '380.00', 'Pending', 'Navy Blue', NULL, '59.00', 'TRK-23-1747637361', NULL, NULL, NULL),
(74, 64, 3, 233, 1, 'Small', '359.00', 'Delivered', 'Black', 4, '59.00', 'TRK-3-1747859064', 'static/delivery_proofs\\proof_74_d0a30e01bbd44984abb0ab102fa3c561.jpg', '2025-05-22 04:32:45', '2025-05-22 04:32:27'),
(75, 65, 4, 118, 1, 'Medium', '289.00', 'Delivered', 'Grey', 4, '59.00', 'TRK-4-1747859107', 'static/delivery_proofs\\proof_75_e1cffb436615464ab170e2cadee66674.jpg', '2025-05-22 04:35:55', '2025-05-22 04:35:55'),
(76, 66, 3, 233, 1, 'Small', '359.00', 'Out for Delivery', 'Black', 4, '0.00', 'TRK-FCF0417DDC', NULL, NULL, '2025-05-22 06:45:17'),
(77, 67, 6, 140, 1, '28', '449.00', 'Out for Delivery', 'Black', 4, '0.00', 'TRK-41447F107F', NULL, NULL, '2025-05-22 09:36:15'),
(78, 68, 26, 184, 1, 'L', '99.00', 'Delivered', 'Grey', 4, '0.00', 'TRK-E611F11FAD', 'static/delivery_proofs\\proof_78_1ca286c9b40149e999827796a2fb8079.jpg', '2025-05-22 09:37:53', '2025-05-22 09:37:53'),
(79, 69, 35, 221, 3, '40', '488.00', 'Delivered', 'Black', 5, '59.00', 'TRK-35-1747879858', 'static/delivery_proofs\\proof_79_c6ec74d2b53940cf87c72c0303b0577e.jpg', '2025-05-22 10:15:36', '2025-05-22 10:15:36');

-- --------------------------------------------------------

--
-- Table structure for table `order_status_log`
--

CREATE TABLE `order_status_log` (
  `id` int(11) NOT NULL,
  `order_item_id` int(11) NOT NULL,
  `status` varchar(50) NOT NULL,
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `changed_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `order_status_log`
--

INSERT INTO `order_status_log` (`id`, `order_item_id`, `status`, `changed_at`, `changed_by`) VALUES
(1, 60, 'Approved', '2025-05-21 20:01:10', '5'),
(2, 60, 'Preparing to Ship', '2025-05-21 20:03:25', '5'),
(3, 60, 'Package Pick-up', '2025-05-21 20:03:28', '5'),
(4, 60, 'Intransit', '2025-05-21 20:03:31', '5'),
(6, 60, 'Out for Delivery', '2025-05-21 20:19:54', 'System'),
(7, 74, 'Approved', '2025-05-21 20:24:38', '5'),
(8, 74, 'Preparing to Ship', '2025-05-21 20:24:41', '5'),
(9, 74, 'Package Pick-up', '2025-05-21 20:24:44', '5'),
(10, 74, 'Intransit', '2025-05-21 20:24:47', '5'),
(11, 75, 'Approved', '2025-05-21 20:25:41', '5'),
(12, 75, 'Preparing to Ship', '2025-05-21 20:25:44', '5'),
(13, 75, 'Package Pick-up', '2025-05-21 20:26:05', '5'),
(14, 75, 'Intransit', '2025-05-21 20:26:11', '5'),
(15, 74, 'Out for Delivery', '2025-05-21 20:32:27', 'System'),
(16, 75, 'Out for Delivery', '2025-05-21 20:35:20', 'System'),
(17, 75, 'Delivered', '2025-05-21 20:35:55', 'Rider'),
(18, 76, 'Pending', '2025-05-21 21:06:42', 'System'),
(19, 76, 'Approved', '2025-05-21 22:24:03', '5'),
(20, 76, 'Preparing to Ship', '2025-05-21 22:24:06', '5'),
(21, 76, 'Package Pick-up', '2025-05-21 22:24:09', '5'),
(22, 76, 'Intransit', '2025-05-21 22:24:53', '5'),
(23, 76, 'Out for Delivery', '2025-05-21 22:45:17', 'System'),
(24, 77, 'Pending', '2025-05-21 22:48:02', 'System'),
(25, 77, 'Approved', '2025-05-21 22:48:36', '5'),
(26, 77, 'Preparing to Ship', '2025-05-21 22:48:38', '5'),
(27, 77, 'Package Pick-up', '2025-05-21 22:48:41', '5'),
(28, 77, 'Intransit', '2025-05-21 22:48:43', '5'),
(29, 78, 'Pending', '2025-05-22 01:14:14', 'System'),
(30, 78, 'Approved', '2025-05-22 01:15:26', '4'),
(31, 78, 'Preparing to Ship', '2025-05-22 01:15:51', '4'),
(32, 78, 'Package Pick-up', '2025-05-22 01:16:07', '4'),
(33, 78, 'Intransit', '2025-05-22 01:16:42', '4'),
(34, 77, 'Out for Delivery', '2025-05-22 01:36:15', 'System'),
(35, 78, 'Out for Delivery', '2025-05-22 01:37:24', 'System'),
(36, 78, 'Delivered', '2025-05-22 01:37:53', 'Rider'),
(37, 79, 'Approved', '2025-05-22 02:11:57', '4'),
(38, 79, 'Preparing to Ship', '2025-05-22 02:12:26', '4'),
(39, 79, 'Package Pick-up', '2025-05-22 02:12:35', '4'),
(40, 79, 'Intransit', '2025-05-22 02:12:44', '4'),
(41, 79, 'Out for Delivery', '2025-05-22 02:14:49', 'System'),
(42, 79, 'Delivered', '2025-05-22 02:15:36', 'Rider');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `product_id` int(11) NOT NULL,
  `seller_id` int(11) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `description` text NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `category` varchar(100) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `stock_quantity` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`product_id`, `seller_id`, `name`, `description`, `price`, `category`, `image`, `stock_quantity`, `created_at`, `updated_at`) VALUES
(3, 5, 'Casual Blazers', 'Lightweight Business Suit Jacket Blazer for Men Summer Thin Sun Protection Suit', '359.00', 'Suits & Blazers', 'uploads/2356be06-3336-4a13-9e96-8e1d3ee2b570.jpg', 15, '2024-11-07 14:38:33', '2025-05-21 20:32:45'),
(4, 5, 'Fashion Loose Version', 'Fashion College style loose suit Plus size 45KG-90KG', '289.00', 'Suits & Blazers', 'uploads/c26dc293-c02b-4cdd-ba08-b17b0dbcb549.jpg', 29, '2024-11-11 07:56:04', '2025-05-21 20:35:55'),
(5, 5, 'Wedding Suit', '2-Pieces Wedding Men\'s Suits Casual Formal Business Blazer Set Slim Fit Suit', '686.00', 'Suits & Blazers', 'uploads/2be8a46a-7799-4dec-a0fd-431e815a4a43.jpg', 88, '2024-11-11 08:04:23', '2024-11-11 14:50:06'),
(6, 5, 'Formal Suit Pants', 'Stretchable Slim Fit Business Office Wear ', '449.00', 'Casual Shirts & Pants', 'uploads/32429f30-6915-4829-baa1-57cce0e6f0ba.jpg', 99, '2024-11-11 08:16:36', '2025-05-21 18:32:41'),
(7, 5, 'Spring Autumn ', 'Men Blazer Color Block Long Sleeve Turndown Collar One Button Slim Suit Jacket for Office', '634.00', 'Suits & Blazers', 'uploads/456a4e14-9aaa-4a42-a977-f5a44eebb9b8.jpg', 40, '2024-11-11 08:53:13', '2024-11-11 08:53:13'),
(18, 5, 'Bomber Jacket', 'Zipper and Pockets Polo Neck Windbreaker Korean Motorcycle Jackets', '349.00', 'Outerwear & Jackets', 'uploads/c7df0abb-af87-4b00-807a-a63b83d6342e.jpg', 40, '2024-11-12 14:47:02', '2024-11-12 14:47:02'),
(20, 5, 'Shaver', '5 IN 1 Multifunction ElectricRazor For Men Rechargeable Professional Razor', '739.00', 'Grooming Products', 'uploads/6bbdce00-e9ce-47ce-b839-2e7056535f97.png', 19, '2024-11-12 15:01:49', '2025-05-21 20:21:51'),
(21, 4, 'Formal jacket', 'korean fashion high Good quality Bomber jacket Double pocket Polo Jacket', '348.00', 'Outerwear & Jackets', 'uploads/3c54960e-42e5-47ed-993c-4440a090fa18.jpg', 60, '2024-11-12 16:34:09', '2024-11-12 16:34:09'),
(22, 4, 'Bomber jacket', 'korean fashion high Good quality, New desigh Polo Collar With Zippee', '550.00', 'Outerwear & Jackets', 'uploads/7d6b9674-7d17-45ca-abb8-a716d369feae.jpg', 40, '2024-11-12 16:40:10', '2024-11-12 16:40:10'),
(23, 4, 'Business Jackets ', '[About the product]: We accept cash on delivery and credit card. After the payment is completed, the baby will send the product to the customer as soon as possible.', '380.00', 'Outerwear & Jackets', 'uploads/a9a26cc4-ce53-446b-9669-d93b69ba4e52.jpg', 40, '2024-11-12 16:46:59', '2024-11-12 16:46:59'),
(24, 4, 'zipper Tops korean', 'STRICTLY \"NO RETURN, NO EXCHANGE!\" except proven defective/damaged, we can only accept the item if its defective but when it comes to sizes we won’t take any responsible.', '188.00', 'Outerwear & Jackets', 'uploads/17143e0d-fe24-4969-b819-f34472773d12.jpg', 39, '2024-11-12 16:52:39', '2025-05-19 06:43:27'),
(25, 4, 'Formal Jacket ', ' Zipper and Pockets Polo Neck Windbreaker Korean Casual Business Jackets', '335.00', 'Outerwear & Jackets', 'uploads/bd176c10-5969-4378-a521-6730d13911bf.jpg', 40, '2024-11-12 16:58:37', '2024-11-12 16:58:37'),
(26, 4, 'JACKET', 'AFFORDABLE PRICE SUITS FOR ANY OCCASION GOOD QUALITY AND TEST', '99.00', 'Outerwear & Jackets', 'uploads/54aaff79-0b4e-414e-a1f8-c09265e562b9.jpg', 39, '2024-11-12 17:04:10', '2025-05-22 01:37:53'),
(27, 4, 'Baolaiwu', 'Jackets Spring Autumn Casual Coats Plaid Bomber Jacket Slim Fashion Male Outwear', '760.00', 'Outerwear & Jackets', 'uploads/f927c277-6eb8-4ffa-b575-1d38a717179c.png', 40, '2024-11-12 17:33:33', '2024-11-12 17:33:33'),
(31, 5, 'Casual Suit Pants', 'Must Have For Fashionable And Relaxed Style', '139.00', 'Casual Shirts & Pants', 'uploads/3d3a8fbc-1037-488a-b9c1-0ab9ab1d578e.png', 40, '2024-11-12 19:24:42', '2024-11-12 19:24:42'),
(32, 5, 'Casual Fashion Business', 'Formal Lapel Knit Shirt Men Shirt Long Sleeved Shirt Plus Size', '196.00', 'Casual Shirts & Pants', 'uploads/c98d590c-80eb-485a-a1b4-da1c7ab72117.png', 40, '2024-11-12 19:29:28', '2024-11-12 19:29:28'),
(33, 4, 'Knee Support ', 'for basketball Pressurized Elastic Knee Pads Fitness Patella Medial Support Protector', '129.00', 'Activewear & Fitness Gear', 'uploads/0d3b9059-674e-484d-b766-e0d02b1a9ae9.png', 40, '2024-11-12 19:33:18', '2024-11-12 19:33:18'),
(34, 4, 'Sports Kneepad', 'Professional Protective Pressurized Elastic Support Fitness Gear', '114.00', 'Activewear & Fitness Gear', 'uploads/53177df5-f39b-47e3-affb-80050b95b853.png', 38, '2024-11-12 19:35:30', '2025-05-18 22:26:06'),
(35, 4, 'casual slip', 'fashion Doudou shoes WP-609', '488.00', 'Shoes & Accessories', 'uploads/a86fd4a7-c4df-4ee3-86ec-6601ea966900.png', 35, '2024-11-12 19:40:53', '2025-05-22 02:15:36'),
(36, 4, 'kkaax Precision 6 ', 'Basketball Shoes Casual Rubber Sneakers Shoes ', '619.00', 'Shoes & Accessories', 'uploads/9925caa9-9089-4a08-94a9-39116eac255a.png', 40, '2024-11-12 19:44:52', '2024-11-12 19:44:52'),
(37, 4, 'Leather Shoes', 'PU LEATHER MADE\r\nOFFICE AND CASUAL WEAR\r\n\r\n', '188.00', 'Shoes & Accessories', 'uploads/ca1e5dda-ae11-48a5-9ed4-bb052b15d2a0.png', 39, '2024-11-12 19:48:36', '2025-05-19 06:03:44');

-- --------------------------------------------------------

--
-- Table structure for table `product_reviews`
--

CREATE TABLE `product_reviews` (
  `id` int(11) NOT NULL,
  `order_item_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `rating` int(11) DEFAULT NULL CHECK (`rating` between 1 and 5),
  `review_text` text DEFAULT NULL,
  `media_url` text DEFAULT NULL,
  `media_type` enum('image','video') DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `product_reviews`
--

INSERT INTO `product_reviews` (`id`, `order_item_id`, `product_id`, `user_id`, `rating`, `review_text`, `media_url`, `media_type`, `created_at`) VALUES
(1, 75, 4, 84, 5, 'sobrang solid goods Ang quality ', 'static/review_media/review_75_00a7dd1ed79940d8b33883c20e012740.jpg', 'image', '2025-05-22 05:34:01');

-- --------------------------------------------------------

--
-- Table structure for table `product_variations`
--

CREATE TABLE `product_variations` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `size` varchar(50) DEFAULT NULL,
  `color` varchar(50) DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `product_variations`
--

INSERT INTO `product_variations` (`id`, `product_id`, `size`, `color`, `quantity`, `image_path`, `price`) VALUES
(118, 4, 'Medium', 'Grey', 7, 'uploads/95727277-3c7b-4cb3-b2f2-c6e2a6ee959c.jpg', '289.00'),
(119, 4, 'Large', 'Grey', 10, 'uploads/b42d69b3-e96d-4a51-9793-86bca729beaf.jpg', '299.00'),
(120, 4, 'Extra Large', 'Grey', 8, 'uploads/0537badf-dc91-4ede-872b-dd56cd772f77.jpg', '309.00'),
(121, 5, 'M', 'Black', 10, 'uploads/e618c042-1bf4-441f-bfac-6984b3835e64.jpg', '686.00'),
(122, 5, 'L', 'Black', 10, 'uploads/42351c0c-9e50-4ede-8fed-f41f6d9b3a31.jpg', '696.00'),
(123, 5, 'XL', 'Black', 10, 'uploads/495c24a3-67a1-412b-a7ec-e989b90fc646.jpg', '706.00'),
(124, 5, 'M', 'White', 10, 'uploads/8d8e585d-74eb-4481-b9c5-8993f70f7aa4.jpg', '686.00'),
(125, 5, 'L', 'White', 10, 'uploads/41a1cc2b-9352-4b5e-ad4a-2ffe61ef11f8.jpg', '696.00'),
(126, 5, 'XL', 'White', 7, 'uploads/35c62771-0589-491b-861f-f889a7be3b5a.jpg', '706.00'),
(127, 5, 'M', 'Blue', 10, 'uploads/5360a69d-0eab-437e-a9f0-2b005e236d13.jpg', '686.00'),
(128, 5, 'L', 'Blue', 10, 'uploads/08a49f91-0e2a-4797-bca6-8808b073f7eb.jpg', '696.00'),
(129, 5, 'XL', 'Blue', 9, 'uploads/eb735f89-9859-4073-b517-70198f10dd88.jpg', '706.00'),
(140, 6, '28', 'Black', 9, 'uploads/d9927462-2b8f-4197-bd98-543ad0328553.jpg', '449.00'),
(141, 6, '29', 'Black', 10, 'uploads/b4e1f941-65ea-4265-b934-6ecf8354aa66.jpg', '454.00'),
(142, 6, '30', 'Black', 10, 'uploads/55bb2588-e81c-4334-8fee-2601a430645a.jpg', '459.00'),
(143, 6, '31', 'Black', 10, 'uploads/ca7bbb82-e9d2-4dc1-a259-f3611cf27a32.jpg', '464.00'),
(144, 6, '32', 'Black', 10, 'uploads/27d706a0-7e42-40a8-a44e-75c93ae89e79.jpg', '469.00'),
(145, 6, '28', 'Navy Blue', 10, 'uploads/0de8a663-712a-4de8-93c8-e98218043455.jpg', '449.00'),
(146, 6, '29', 'Navy Blue', 10, 'uploads/b533fd30-d062-406d-8337-f2d0ae8c715e.jpg', '454.00'),
(147, 6, '30', 'Navy Blue', 10, 'uploads/7a601cbc-7c1c-4869-b319-466f9d09459a.jpg', '459.00'),
(148, 6, '31', 'Navy Blue', 10, 'uploads/c655aa51-489f-4692-84cc-b144f2b98948.jpg', '464.00'),
(149, 6, '32', 'Navy Blue', 10, 'uploads/086f9df4-33aa-4bc0-98eb-aebde30539ab.jpg', '469.00'),
(150, 7, 'M', 'Black', 10, 'uploads/2fb52346-bda6-4ebf-9256-b5fc7a582df0.jpg', '634.00'),
(151, 7, 'M', 'White', 10, 'uploads/94c45bff-7641-4bb4-9d3a-899a6fd1a2ab.jpg', '634.00'),
(152, 7, 'L', 'White', 10, 'uploads/ff38cc59-bc54-4d07-a0ce-d9eb21be79b5.jpg', '644.00'),
(153, 7, 'L', 'Black', 10, 'uploads/94480ba7-5c71-4ef9-ba02-4bd0d555110d.jpg', '644.00'),
(155, 18, 'M (50~60kg)', 'Navy Blue', -40, 'uploads/28e8a139-8a58-44db-bb6f-72491ce93e0c.jpg', '349.00'),
(156, 18, 'L (61~65kg)', 'Navy Blue', 9, 'uploads/9eb58bf7-1527-455a-bdfe-5d1308cb624b.jpg', '349.00'),
(157, 18, 'M (50~60kg)', 'Black', 10, 'uploads/44422a01-e2f3-4743-9c14-466b3dd7dd42.jpg', '349.00'),
(158, 18, 'L (61~65kg)', 'Black', 10, 'uploads/aca3824a-ed1f-4722-9929-39a3ed8662ac.jpg', '349.00'),
(161, 21, 'M(50~60Kg)', 'Black', 10, 'uploads/bdf01323-04c5-4178-acbc-ecc241db1dcd.jpg', '349.00'),
(162, 21, 'L(61~65Kg)', 'Black', 10, 'uploads/0c6c760f-5af1-4941-8ea8-8496912966f7.jpg', '348.00'),
(163, 21, 'XL(66~70Kg)', 'Black', 10, 'uploads/0e0c2004-610f-4046-a469-d841496d8d54.jpg', '348.00'),
(164, 21, 'M(50~60Kg)', 'Navy Blue', 10, 'uploads/c2151d5e-91fd-456c-9311-3854e494ea37.jpg', '348.00'),
(165, 21, 'L(61~65Kg)', 'Navy Blue', 10, 'uploads/deb5b56d-1cff-43b7-8a22-dcc3ef092130.jpg', '348.00'),
(166, 21, 'XL(66~70Kg)', 'Navy Blue', 10, 'uploads/8f31142d-c313-493a-a696-f207b97a622d.jpg', '348.00'),
(167, 22, 'Large', 'Black', 10, 'uploads/6dce9b06-22eb-4425-8fd7-de57d68c11b6.jpg', '550.00'),
(168, 22, 'XL', 'Black', 10, 'uploads/cca3240a-fadd-4aed-b4b9-20980ed19691.jpg', '550.00'),
(169, 22, 'Large', 'Blue', 10, 'uploads/e6ded339-c824-4b7d-8563-c9550b3fd681.jpg', '550.00'),
(170, 22, 'XL', 'Blue', 10, 'uploads/ad2ae98b-5604-41e0-bc6e-8036001d4447.jpg', '550.00'),
(171, 23, 'L', 'Black', 10, 'uploads/52f929e6-b103-4413-a177-fb3f005b07db.jpg', '380.00'),
(172, 23, 'XL', 'Black', 10, 'uploads/81592988-d3d7-432d-a157-55d982df654a.jpg', '380.00'),
(173, 23, 'L', 'Navy Blue', 9, 'uploads/a7d5f77b-954b-4cb9-9c8a-01b3e265c596.jpg', '380.00'),
(174, 23, 'XL', 'Navy Blue', 10, 'uploads/0921a7ae-9898-4420-9f60-c7b897b74e5e.jpg', '380.00'),
(175, 24, 'M', 'Maroon', 10, 'uploads/53bc0819-e9ba-4012-8c4c-b05758550242.jpg', '188.00'),
(176, 24, 'L', 'Maroon', 9, 'uploads/e1d7460f-c3b0-4a45-bfbc-0d0e1a3e86f9.jpg', '188.00'),
(177, 24, 'M', 'Black', 10, 'uploads/60bc932f-7d47-4cfd-9f6b-ecbc816ba011.jpg', '188.00'),
(178, 24, 'L', 'Black', 10, 'uploads/9e41183d-54ab-4aba-bdb9-40af1cfe8bd3.jpg', '188.00'),
(179, 25, 'M', 'Black', 10, 'uploads/99bd7a75-c7db-4a2c-89cd-fcf6f155b084.jpg', '335.00'),
(180, 25, 'L', 'Black', 10, 'uploads/4c8211f2-737a-42dc-8e09-57f72f6543c4.jpg', '335.00'),
(181, 25, 'M', 'Tan', 10, 'uploads/5277bda8-45a5-4883-a78c-67fcb698d4de.jpg', '335.00'),
(182, 25, 'L', 'Tan', 10, 'uploads/8ad7acaf-0a2a-4d85-8feb-f94aedbb4087.jpg', '335.00'),
(183, 26, 'M', 'Grey', 9, 'uploads/afbd0848-4e08-4a95-a564-b91f0dc083fa.jpg', '99.00'),
(184, 26, 'L', 'Grey', 10, 'uploads/b2a2e9b2-6dc0-43a0-8d04-ae47cf4a6a5d.jpg', '99.00'),
(185, 26, 'M', 'Blue', 10, 'uploads/1fcbe245-e819-4893-9b49-6909b2812c0a.jpg', '99.00'),
(186, 26, 'L', 'Blue', 10, 'uploads/8a2d30a7-598c-4b47-bdf2-f6f2e89330bd.jpg', '99.00'),
(199, 20, 'Long 5 in 1', 'Black', 9, 'uploads/78902b95-9b47-4d45-b6dd-f3fd65bfafa2.png', '739.00'),
(200, 20, 'Upgraded short 5 in 1', 'Black', 10, 'uploads/d2583214-7333-4ab9-bfbe-2f14bfca6d1e.png', '774.00'),
(201, 27, 'M', 'Blue', 10, 'uploads/e77df848-8b1c-4e8f-9e66-d774158afdd6.jpg', '760.00'),
(202, 27, 'L', 'Blue', 10, 'uploads/ad88d226-ee18-4bde-958c-87dd5351eec5.jpg', '760.00'),
(203, 27, 'M', 'Red', 10, 'uploads/be37aab7-6719-49a2-bf39-b3e582c1f3b8.jpg', '760.00'),
(204, 27, 'L', 'Red', 10, 'uploads/59a512af-2ca9-4d84-bf59-2385e9f5698a.jpg', '760.00'),
(205, 31, 'M', 'Black', 10, 'uploads/470cf92a-a709-4cf8-b1d6-ecafc9e5aa4b.png', '139.00'),
(206, 31, 'L', 'Black', 10, 'uploads/7715aae7-63b2-4e8e-8482-dc02a773331e.png', '139.00'),
(207, 31, 'M', 'Khaki', 10, 'uploads/a5bccf12-a9e5-4436-ad72-f00fac4514cd.png', '139.00'),
(208, 31, 'L', 'Khaki', 10, 'uploads/1fbaf021-f792-4d44-b36c-b705f177502d.png', '139.00'),
(209, 32, 'M', 'White', 10, 'uploads/bd1a6794-36ba-4b5a-9141-f5cc92d4629d.png', '196.00'),
(210, 32, 'L', 'White', 10, 'uploads/5ba31608-a8bc-46f1-a505-ad910cae2f58.png', '196.00'),
(211, 32, 'L', 'Black', 10, 'uploads/d92de48e-9564-460f-ad52-afbba26a16aa.png', '196.00'),
(212, 32, 'M', 'Black', 10, 'uploads/c29f924a-1a7b-4229-b9ea-42ef305c87d3.png', '196.00'),
(213, 33, 'M', 'Black', 10, 'uploads/a7fa0175-5765-48fe-b4d1-ecba273d2f36.png', '129.00'),
(214, 33, 'L', 'Black', 10, 'uploads/1797dab9-59e1-4c8e-a004-3ee3f834d4df.png', '129.00'),
(215, 33, 'M', 'Grey', 10, 'uploads/fdd50d0f-d097-4297-aa85-a1e1e35409d7.png', '129.00'),
(216, 33, 'L', 'Grey', 10, 'uploads/9d6d22e6-e430-4772-92a1-ac5e7645b9ef.png', '129.00'),
(217, 34, 'M', 'Red', 9, 'uploads/cd7ddced-11d8-44fc-a4ab-007212e80dc1.png', '114.00'),
(218, 34, 'L', 'Red', 10, 'uploads/0a926573-9b6c-4b8e-80c9-507b5caed70c.png', '114.00'),
(219, 34, 'M', 'Black', 8, 'uploads/6faad923-4ee6-4b64-a4d9-c36ebf62def0.png', '114.00'),
(220, 34, 'L', 'Black', 10, 'uploads/46706a8e-27db-48f9-9823-3bf2d1f3dd79.png', '114.00'),
(221, 35, '40', 'Black', 7, 'uploads/130c13d3-7bf7-4174-944a-cde139ef4900.png', '488.00'),
(222, 35, '41', 'Black', 8, 'uploads/0ba1f5af-12f6-4340-9086-0dc8c76ae5c3.png', '488.00'),
(223, 35, '40', 'Coffee', 8, 'uploads/535023a4-7f68-4911-8cc7-bafe0eb6e7ae.png', '488.00'),
(224, 35, '41', 'Coffee', 10, 'uploads/69b682fd-47fa-44cf-bf8c-e71c86afcb43.png', '488.00'),
(225, 36, '41', 'Grafiti', 10, 'uploads/58da51f0-eda0-4abd-a98c-33b6403dbf92.png', '619.00'),
(226, 36, '42', 'Grafiti', 10, 'uploads/d36a102b-150b-4195-a495-68e8eb36e0c2.png', '619.00'),
(227, 36, '41', 'Panda', 10, 'uploads/ec62cc80-9df0-4130-a93a-258dcc64926f.png', '619.00'),
(228, 36, '42', 'Panda', 10, 'uploads/ddea4f1f-b496-4b91-9d75-5b3833cc4efe.png', '619.00'),
(229, 37, '41', 'Black', 10, 'uploads/a9f28c2c-2e9a-49fa-a551-34c91bcbd23b.png', '188.00'),
(230, 37, '42', 'Black', 10, 'uploads/e81f92fc-f2f5-4834-a547-cdb1f5096f17.png', '188.00'),
(231, 37, '41', 'Brown', 9, 'uploads/8ec4e64d-cf60-4c83-bb0b-bd2b9d81cc04.png', '188.00'),
(232, 37, '42', 'Brown', 9, 'uploads/100603ff-eae0-4295-a86d-9a70fc2e5d7b.png', '188.00'),
(233, 3, 'Small', 'Black', 9, 'uploads/c6a3bf24-f674-406c-a270-fd69d96ab518.jpg', '359.00'),
(234, 3, 'Small', 'White', 4, 'uploads/4dcc0347-b405-42e9-8bb1-2b8092f0a69b.jpg', '359.00'),
(235, 3, 'Small', 'Blue', 2, 'uploads/d3d33028-793a-4591-a063-cd3229e1a982.jpg', '359.00');

-- --------------------------------------------------------

--
-- Table structure for table `profile_pictures`
--

CREATE TABLE `profile_pictures` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `picture_url` varchar(255) NOT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `profile_pictures`
--

INSERT INTO `profile_pictures` (`id`, `user_id`, `picture_url`, `uploaded_at`) VALUES
(4, 84, 'static/profile_images/382bb7e7-f355-4f0f-be51-197484a1ebf5.jpg', '2024-11-27 10:18:46'),
(6, 107, 'static/profile_images/d1630e76-abf4-4452-b997-c43555784505.jpg', '2024-11-29 09:53:01'),
(7, 81, 'static/profile_images\\e96c7d49-ed0a-4455-b10d-4df3aa8eb86f.jpg', '2024-11-30 08:17:07');

-- --------------------------------------------------------

--
-- Table structure for table `riders`
--

CREATE TABLE `riders` (
  `id` int(11) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `contact_number` varchar(11) NOT NULL,
  `birthday` date NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `license_photo` varchar(255) NOT NULL,
  `vehicle_type` enum('motorcycle','van','car') NOT NULL,
  `status` enum('pending','approved','declined') NOT NULL DEFAULT 'pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `riders`
--

INSERT INTO `riders` (`id`, `first_name`, `last_name`, `middle_name`, `contact_number`, `birthday`, `email`, `password`, `license_photo`, `vehicle_type`, `status`) VALUES
(4, 'THIRD', 'MOVIDA', 'ALFONSO', '09630808679', '2002-02-07', 'alfonsomovida@gmail.com', '123123', 'rider_licenses/841d2306-85f3-471f-9670-3e6d976a9423.jpg', 'van', 'approved'),
(5, 'Raymond', 'Rivarez', 'Valenzuela', '09515997230', '2010-07-12', 'ryanrivarez7@gmail.com', '123123', '', 'motorcycle', 'approved');

-- --------------------------------------------------------

--
-- Table structure for table `rider_address`
--

CREATE TABLE `rider_address` (
  `id` int(11) NOT NULL,
  `rider_id` int(11) NOT NULL,
  `street` varchar(255) DEFAULT NULL,
  `barangay` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `region` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `rider_address`
--

INSERT INTO `rider_address` (`id`, `rider_id`, `street`, `barangay`, `city`, `province`, `region`, `created_at`, `updated_at`) VALUES
(1, 4, 'Kaingin', 'San Antonio', 'Bay', 'Laguna', 'Calabazon', '2025-05-22 01:19:34', '2025-05-22 01:19:38');

-- --------------------------------------------------------

--
-- Table structure for table `seller_shops`
--

CREATE TABLE `seller_shops` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `shop_name` varchar(255) NOT NULL,
  `shop_image` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `seller_shops`
--

INSERT INTO `seller_shops` (`id`, `user_id`, `shop_name`, `shop_image`, `created_at`) VALUES
(4, 83, 'PJOs Clothing', 'shop_images/87b97863-7fb8-4932-ac8e-3c8b58e9777b.jpg', '2024-11-26 15:42:52');

-- --------------------------------------------------------

--
-- Table structure for table `shipping_address`
--

CREATE TABLE `shipping_address` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `region` varchar(100) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `barangay` varchar(100) DEFAULT NULL,
  `street` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `shipping_address`
--

INSERT INTO `shipping_address` (`id`, `user_id`, `region`, `province`, `city`, `barangay`, `street`) VALUES
(128, 81, 'Region IV-A (CALABARZON)', 'Laguna', 'Pila', 'Bulilan Sur ', '188 Mabini'),
(129, 84, 'Region IV-A (CALABARZON)', 'Laguna', 'Pila', 'Santa Clara Sur ', 'codera'),
(152, 107, 'Region IV-A (CALABARZON)', 'Laguna', 'Santa Cruz ', 'Santisima Cruz', '0639 kamagong'),
(154, 112, 'Region III (Central Luzon)', 'Bulacan', 'Norzagaray', 'San Lorenzo', 'codera');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `contact_number` varchar(15) NOT NULL,
  `birthday` date NOT NULL,
  `email` varchar(100) NOT NULL,
  `role` enum('buyer','seller','admin') NOT NULL,
  `photo` varchar(255) DEFAULT NULL,
  `age` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `password` varchar(255) NOT NULL,
  `status` enum('active','blocked','pending') NOT NULL DEFAULT 'active',
  `reset_token` varchar(255) DEFAULT NULL,
  `reset_token_expiration` datetime DEFAULT NULL,
  `blocked_until` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `first_name`, `last_name`, `middle_name`, `contact_number`, `birthday`, `email`, `role`, `photo`, `age`, `created_at`, `password`, `status`, `reset_token`, `reset_token_expiration`, `blocked_until`) VALUES
(4, 'pj', 'andallo ', '', '09604651836', '2003-07-29', 'pogipj59@gmail.com', 'seller', 'IDs/78ea3fb0-bd29-466f-920a-2996e9ef8406.jpg', 21, '2024-10-07 07:52:43', 'Pjo123', 'active', NULL, NULL, NULL),
(5, 'Fresdie', 'Andallo II', 'pimentel', '09604651836', '2003-07-29', 'fresdieii@gmail.com', 'seller', 'IDs/e2b84719-0100-4c38-a90e-d59b12d14c0f.png', 21, '2024-10-07 11:12:42', 'Pj123123', 'active', NULL, NULL, NULL),
(9, 'geryanne', 'Cosep', NULL, '09752484620', '2000-10-02', 'geryannecosepII@gmail.com', 'admin', NULL, 23, '2024-10-19 05:21:23', 'admin123', 'active', NULL, NULL, NULL),
(81, 'Alfredo', 'Joya', '', '09630808679', '2003-07-29', 'alfredojoya23@gmail.com', 'buyer', 'IDs/815807a7-3cc1-4fc7-94a0-36beb9f9d634.jpg', 21, '2024-11-26 14:22:07', 'Jr123', 'blocked', '828399', '2024-12-07 23:02:27', NULL),
(83, 'Fresdie', 'Andallo', '', '09630808679', '2003-07-29', 'fresdiea@gmail.com', 'seller', 'IDs/db526d40-3e84-4506-b5bc-98ab0fb58af6.jpg', 21, '2024-11-26 15:42:52', '123123', 'active', NULL, NULL, NULL),
(84, 'Raymond', 'Rivarez', '', '09630808679', '2003-07-29', 'raymondrivarez23@gmail.com', 'buyer', 'IDs/79efb014-7619-4c9c-89db-75f31312516d.jpg', 21, '2024-11-26 15:50:07', 'raymond15', 'active', NULL, NULL, NULL),
(107, 'Pj', 'Andallo', '', '09630808679', '2003-07-29', 'pjandallo29@gmail.com', 'buyer', 'IDs/3f2ac23a-7c9e-4420-939f-2e157bb39809.jpg', 21, '2024-11-29 09:51:45', '123123', 'active', NULL, NULL, NULL),
(112, 'alffin', 'Andrade', '', '09630808679', '2000-01-01', 'alffinandrade@gmail.com', 'buyer', 'IDs/20ea3080-bcf1-4632-a694-5934b9b890f2.jpg', 25, '2025-05-22 02:19:51', 'Alffin123', 'active', NULL, NULL, NULL);

--
-- Triggers `users`
--
DELIMITER $$
CREATE TRIGGER `before_insert_user` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
    IF NEW.role = 'seller' THEN
        SET NEW.status = 'pending';
    ELSE
        SET NEW.status = 'active';
    END IF;
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`cart_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `sender_id` (`sender_id`),
  ADD KEY `receiver_id` (`receiver_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `shipping_id` (`shipping_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `fk_product_variation_id` (`product_variation_id`),
  ADD KEY `rider_id` (`rider_id`);

--
-- Indexes for table `order_status_log`
--
ALTER TABLE `order_status_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_item_id` (`order_item_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_id`),
  ADD KEY `seller_id` (`seller_id`);

--
-- Indexes for table `product_reviews`
--
ALTER TABLE `product_reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_item_id` (`order_item_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `product_variations`
--
ALTER TABLE `product_variations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `profile_pictures`
--
ALTER TABLE `profile_pictures`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `riders`
--
ALTER TABLE `riders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `contact_number` (`contact_number`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `rider_address`
--
ALTER TABLE `rider_address`
  ADD PRIMARY KEY (`id`),
  ADD KEY `rider_id` (`rider_id`);

--
-- Indexes for table `seller_shops`
--
ALTER TABLE `seller_shops`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `shipping_address`
--
ALTER TABLE `shipping_address`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `cart`
--
ALTER TABLE `cart`
  MODIFY `cart_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=125;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=70;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=80;

--
-- AUTO_INCREMENT for table `order_status_log`
--
ALTER TABLE `order_status_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `product_reviews`
--
ALTER TABLE `product_reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `product_variations`
--
ALTER TABLE `product_variations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=236;

--
-- AUTO_INCREMENT for table `profile_pictures`
--
ALTER TABLE `profile_pictures`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `riders`
--
ALTER TABLE `riders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `rider_address`
--
ALTER TABLE `rider_address`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `seller_shops`
--
ALTER TABLE `seller_shops`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `shipping_address`
--
ALTER TABLE `shipping_address`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=155;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=113;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `cart`
--
ALTER TABLE `cart`
  ADD CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`);

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`shipping_id`) REFERENCES `shipping_address` (`id`);

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_product_variation_id` FOREIGN KEY (`product_variation_id`) REFERENCES `product_variations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`),
  ADD CONSTRAINT `rider_id` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`);

--
-- Constraints for table `order_status_log`
--
ALTER TABLE `order_status_log`
  ADD CONSTRAINT `order_status_log_ibfk_1` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`order_item_id`) ON DELETE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`seller_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `product_reviews`
--
ALTER TABLE `product_reviews`
  ADD CONSTRAINT `product_reviews_ibfk_1` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`order_item_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_reviews_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_reviews_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `product_variations`
--
ALTER TABLE `product_variations`
  ADD CONSTRAINT `product_variations_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `profile_pictures`
--
ALTER TABLE `profile_pictures`
  ADD CONSTRAINT `profile_pictures_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rider_address`
--
ALTER TABLE `rider_address`
  ADD CONSTRAINT `rider_address_ibfk_1` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `seller_shops`
--
ALTER TABLE `seller_shops`
  ADD CONSTRAINT `seller_shops_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `shipping_address`
--
ALTER TABLE `shipping_address`
  ADD CONSTRAINT `shipping_address_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
