import traceback
import uuid
from flask import Flask, abort, render_template, request, redirect, url_for, session, flash, request, Response, jsonify, send_from_directory
import mysql.connector
import mysql.connector.cursor
from datetime import datetime, timedelta
from werkzeug.utils import secure_filename
import random
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import json
from decimal import Decimal
from apscheduler.schedulers.background import BackgroundScheduler
import logging
from flask_cors import CORS 
from flask_cors import cross_origin
from collections import defaultdict


app = Flask(__name__, static_folder='static')
app.secret_key = 'supersecretkey'

CORS(app)

# Configure MySQL connection
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database="fara" 
)

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',   # <-- your MySQL password
    'database': 'fara'
}

cursor = db.cursor()

def generate_otp():
    return random.randint(100000, 999999)

UPLOAD_FOLDER = 'static/uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

ID_FOlDER = 'static/IDs'
app.config['ID_FOlDER'] = ID_FOlDER

SHOP_IMAGE_FOLDER = 'static/shop_images'
app.config['SHOP_IMAGE_FOLDER'] = SHOP_IMAGE_FOLDER

PROFILE_PIC_FOLDER = 'static/profile_images'
app.config['PROFILE_PIC_FOLDER'] = PROFILE_PIC_FOLDER


RIDER_LICENSE_FOLDER = 'static/rider_licenses'
app.config['RIDER_LICENSE_FOLDER'] = RIDER_LICENSE_FOLDER

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

if not os.path.exists(ID_FOlDER):
    os.makedirs(ID_FOlDER)

if not os.path.exists(SHOP_IMAGE_FOLDER):
    os.makedirs(SHOP_IMAGE_FOLDER)

if not os.path.exists(PROFILE_PIC_FOLDER):
    os.makedirs(PROFILE_PIC_FOLDER)

# Ensure the folder exists
if not os.path.exists(RIDER_LICENSE_FOLDER):
    os.makedirs(RIDER_LICENSE_FOLDER)


def compute_age(birthday):
    today = datetime.today()
    age = today.year - birthday.year - ((today.month, today.day) < (birthday.month, birthday.day))
    return age


def allowed_file(filename):
    """Check if the file is allowed based on its extension."""
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_extensions

def fetch_products():
    """Fetch all products from the database."""
    try:
        cursor.execute("SELECT * FROM products")
        products = cursor.fetchall()
        print("Fetched products:", products)  # Debugging line
        return products
    except mysql.connector.Error as err:
        print(f"Database error: {err}")
        return []
    
def fetch_products(search_query=None):
    query = "SELECT * FROM products"
    
    # Add search functionality if query is provided
    if search_query:
        query += " WHERE name LIKE %s OR category LIKE %s"
        cursor.execute(query, ('%' + search_query + '%', '%' + search_query + '%'))
    else:
        cursor.execute(query)
    
    products = cursor.fetchall()
    for product in products:
        print(f"Product Image Path: {product[5]}")  # Debug: Check image path
    return products

def send_otp(email, otp):
    sender_email = "fresdiea@gmail.com"
    sender_password = "rjeb kakc kfjp mxma"
    subject = "Your OTP Code for Registration"
    
    # Creating the message
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = email
    message["Subject"] = subject

    body = f"Your OTP code is: {otp}"
    message.attach(MIMEText(body, "plain"))
    
    try:
        # Connect to the mail server and send the email
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(sender_email, sender_password)
        text = message.as_string()
        server.sendmail(sender_email, email, text)
        server.quit()
        return True
    except Exception as e:
        print(f"Failed to send OTP: {e}")
        return False
    
def save_order(user_id, order_items, total_amount, payment_method):
    try:
        # Insert the order into the orders table
        cursor.execute("""
            INSERT INTO orders (user_id, total_amount, payment_method)
            VALUES (%s, %s, %s)
        """, (user_id, total_amount, payment_method))
        order_id = cursor.lastrowid  # Get the generated order_id

        # Insert each order item into the order_items table
        for item in order_items:
            cursor.execute("""
                INSERT INTO order_items (order_id, product_id, quantity, size, price)
                VALUES (%s, %s, %s, %s, %s)
            """, (order_id, item['product_id'], item['quantity'], item['size'], item['price']))

        db.commit()  # Commit the transaction
        return order_id
    except Exception as e:
        db.rollback()  # Rollback in case of error
        flash('An error occurred while placing your order.')
        return None
    
# Routes
@app.route('/')
def home():
    return render_template('login.html')

@app.route('/buyer')
def buyer_homepage():
    # Fetch products from the database
    connection = mysql.connector.connect(host='localhost', user='root', password='', database='fara')
    cursor = connection.cursor(dictionary=True)
    cursor.execute("SELECT * FROM products")
    products = cursor.fetchall()
    cursor.close()
    connection.close()

    # Group products by category and select only one from each category
    unique_categories = {}
    for product in products:
        if product['category'] not in unique_categories:
            unique_categories[product['category']] = product

    # Get a list of the first product of each category
    featured_products = list(unique_categories.values())
    
    # Render template with filtered products
    return render_template('buyer_homepage.html', products=featured_products)
#======================================flutter======================================================
@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(os.path.join(app.static_folder, 'uploads'), filename)

# Route: Get products for buyer home
@app.route('/api/buyer_home', methods=['GET'])
def buyer_home_api():
    db = None
    cursor = None
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Fetch all products
        cursor.execute("""
            SELECT 
                product_id AS id, 
                name, 
                description, 
                price, 
                category, 
                image, 
                stock_quantity 
            FROM products
        """)
        products = cursor.fetchall()

        # Fix image paths (remove redundant prefix if exists)
        for product in products:
            image = product.get('image', '')
            if image.startswith('uploads/'):
                image = image.replace('uploads/', '', 1)
            product['image'] = image.replace('\\', '/')

        # TODO: Replace with dynamic user ID if needed
        user_id = request.args.get('user_id', default=84, type=int)

        # Fetch latest profile picture
        cursor.execute("""
            SELECT picture_url 
            FROM profile_pictures 
            WHERE user_id = %s 
            ORDER BY uploaded_at DESC 
            LIMIT 1
        """, (user_id,))
        profile = cursor.fetchone()

        picture_url = None
        if profile and profile.get('picture_url'):
            picture_url = profile['picture_url'].replace('\\', '/')

        return jsonify({
            'status': 'success',
            'products': products,
            'picture_url': picture_url
        })

    except mysql.connector.Error as err:
        print(f"[Database Error] {err}")
        return jsonify({'status': 'error', 'message': str(err)}), 500

    except Exception as e:
        print(f"[Unknown Error] {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()

# Route: Get product variations
@app.route('/api/product_variations/<int:product_id>', methods=['GET'])
def get_product_variations(product_id):
    db = None
    cursor = None
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT id, product_id, size, color, quantity, image_path, price
            FROM product_variations
            WHERE product_id = %s
        """, (product_id,))
        variations = cursor.fetchall()

        # Clean up image paths for frontend usage
        for variation in variations:
            path = variation.get('image_path')
            if path:
                variation['image_path'] = path.replace('\\', '/')

        return jsonify({
            'status': 'success',
            'variations': variations
        })

    except mysql.connector.Error as err:
        print(f"[Database Error] {err}")
        return jsonify({'status': 'error', 'message': str(err)}), 500

    except Exception as e:
        print(f"[Unknown Error] {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()


@app.route('/api/add_to_cart', methods=['POST'])
@cross_origin()
def add_to_cart_api():
    db = None
    cursor = None
    try:
        data = request.get_json()
        print("Received data:", data)

        # Extract fields
        user_id = data.get('user_id')
        product_id = data.get('product_id')
        quantity = data.get('quantity')
        size = data.get('size')
        color = data.get('color')
        price = data.get('price')
        image_path = data.get('image_path')

        if user_id is None or product_id is None or quantity is None:
            return jsonify({'status': 'error', 'message': 'Missing user_id, product_id, or quantity'}), 400

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Check user existence
        cursor.execute("SELECT id FROM users WHERE id = %s", (user_id,))
        if cursor.fetchone() is None:
            return jsonify({'status': 'error', 'message': 'User not found'}), 404

        # Fetch default variation if fields are missing
        if not all([size, color, price, image_path]):
            cursor.execute("""
                SELECT size, color, price, image_path
                FROM product_variation
                WHERE product_id = %s
                LIMIT 1
            """, (product_id,))
            variation = cursor.fetchone()
            if not variation:
                return jsonify({'status': 'error', 'message': 'Variation not found'}), 400
            size = size or variation['size']
            color = color or variation['color']
            price = price or variation['price']
            image_path = image_path or variation['image_path']

        # Convert and sanitize price
        try:
            price = float(price)
        except (TypeError, ValueError):
            return jsonify({'status': 'error', 'message': 'Invalid price format'}), 400

        # Insert item into cart
        cursor.execute("""
            INSERT INTO cart (user_id, product_id, quantity, size, color, price, image_path, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        """, (user_id, product_id, quantity, size, color, price, image_path.replace('\\', '/')))
        db.commit()

        print(f"Added to cart: user {user_id}, product {product_id}")
        return jsonify({'status': 'success', 'message': 'Product added to cart'}), 200

    except mysql.connector.Error as err:
        print("[MySQL Error]:", err)
        return jsonify({'status': 'error', 'message': str(err)}), 500

    except Exception as e:
        print("[General Error]:", e)
        return jsonify({'status': 'error', 'message': str(e)}), 500

    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()

@app.route('/api/get_cart_items/<int:user_id>', methods=['GET'])
@cross_origin()
def get_cart_items(user_id):
    db = None
    cursor = None
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # 1. Validate user exists
        cursor.execute("SELECT id FROM users WHERE id = %s", (user_id,))
        if cursor.fetchone() is None:
            return jsonify({'status': 'error', 'message': 'User not found'}), 404

        # 2. Get cart items and product/variation info
        cursor.execute("""
            SELECT 
                c.cart_id,
                c.product_id,
                p.name AS product_name,
                c.size,
                c.color,
                c.price,
                c.quantity AS cart_quantity,
                pv.quantity AS variation_quantity,
                c.image_path,
                c.created_at,
                c.updated_at
            FROM 
                cart c
            LEFT JOIN 
                products p ON c.product_id = p.product_id
            LEFT JOIN 
                product_variations pv 
                ON pv.product_id = c.product_id 
                AND pv.size = c.size 
                AND pv.color = c.color
            WHERE 
                c.user_id = %s
        """, (user_id,))
        raw_items = cursor.fetchall()

        # 3. Filter out items without a product name (deleted or invalid product)
        cart_items = [item for item in raw_items if item.get('product_name')]

        # 4. Clean image paths + ensure variation_quantity is an integer
        for item in cart_items:
            # fix image path for Flutter
            path = item.get('image_path')
            if path:
                path = path.replace('\\', '/')
                if not path.startswith('uploads/'):
                    path = f'uploads/{path}'
                item['image_path'] = path

            # ensure quantity is an int (even if null from LEFT JOIN)
            item['variation_quantity'] = int(item.get('variation_quantity') or 0)

        # 5. Return response
        if not cart_items:
            return jsonify({
                'status': 'success',
                'message': 'Cart is empty',
                'cart_items': []
            }), 200

        return jsonify({
            'status': 'success',
            'message': 'Cart retrieved successfully',
            'cart_items': cart_items
        }), 200

    except mysql.connector.Error as err:
        print("[MySQL Error]:", err)
        return jsonify({'status': 'error', 'message': 'Database error occurred'}), 500

    except Exception as e:
        import traceback
        print("[General Error]:", e)
        traceback.print_exc()
        return jsonify({'status': 'error', 'message': 'Internal server error'}), 500

    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()

@app.route('/api/update_cart_item', methods=['POST'])
@cross_origin()
def update_cart_item():
    db = None
    cursor = None
    try:
        data = request.get_json()
        cart_id = data.get('cart_id')
        quantity = data.get('quantity')

        # Validation
        if cart_id is None or quantity is None:
            return jsonify({'status': 'error', 'message': 'Missing cart_id or quantity'}), 400

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor()

        # Update cart quantity
        cursor.execute("""
            UPDATE cart
            SET quantity = %s, updated_at = NOW()
            WHERE cart_id = %s
        """, (quantity, cart_id))

        db.commit()

        return jsonify({'status': 'success', 'message': 'Quantity updated successfully'}), 200

    except mysql.connector.Error as err:
        print("[MySQL Error]:", err)
        return jsonify({'status': 'error', 'message': 'Database error occurred'}), 500

    except Exception as e:
        print("[General Error]:", e)
        return jsonify({'status': 'error', 'message': 'Internal server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/remove_from_cart', methods=['POST'])
@cross_origin()
def api_remove_from_cart():
    try:
        data = request.get_json()
        cart_id = data.get('cart_id')

        if not cart_id:
            return jsonify({'status': 'error', 'message': 'Missing cart_id'}), 400

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor()

        # Delete the cart item
        cursor.execute("DELETE FROM cart WHERE cart_id = %s", (cart_id,))
        db.commit()

        return jsonify({'status': 'success', 'message': 'Item removed from cart'}), 200

    except Exception as e:
        print('[Cart Delete Error]:', e)
        return jsonify({'status': 'error', 'message': 'Failed to remove item'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

        
from flask import Flask, request, jsonify
from flask_cors import cross_origin
from datetime import datetime
import mysql.connector
from collections import defaultdict

@app.route('/api/place_order', methods=['POST'])
@cross_origin()
def api_place_order():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        cart_ids = data.get('cart_ids')
        payment_method = data.get('payment_method', 'cod')

        if not user_id or not cart_ids:
            return jsonify({'status': 'error', 'message': 'Missing user_id or cart_ids'}), 400

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Get shipping address
        cursor.execute("SELECT id FROM shipping_address WHERE user_id = %s LIMIT 1", (user_id,))
        shipping = cursor.fetchone()
        if not shipping:
            return jsonify({'status': 'error', 'message': 'No shipping address found.'}), 400
        shipping_id = shipping['id']

        # Validate cart items
        placeholders = ','.join(['%s'] * len(cart_ids))
        query = f"""
            SELECT c.cart_id, c.product_id, c.size, c.color, c.quantity AS cart_quantity,
                   c.price, pv.id AS variation_id, pv.quantity AS available_stock
            FROM cart c
            JOIN product_variations pv
              ON pv.product_id = c.product_id AND pv.size = c.size AND pv.color = c.color
            WHERE c.user_id = %s AND c.cart_id IN ({placeholders})
        """
        cursor.execute(query, [user_id] + cart_ids)
        items = cursor.fetchall()

        if not items:
            return jsonify({'status': 'error', 'message': 'No valid items found.'}), 400

        # Group quantities by variation and validate against stock
        variation_totals = defaultdict(int)
        variation_stock = {}

        for item in items:
            key = f"{item['product_id']}_{item['size']}_{item['color']}"
            variation_totals[key] += item['cart_quantity']
            variation_stock[key] = item['available_stock']

        for key, total_qty in variation_totals.items():
            if total_qty > variation_stock[key]:
                prod_id, size, color = key.split('_')
                return jsonify({
                    'status': 'error',
                    'message': f"Insufficient stock for product {prod_id} (Size: {size}, Color: {color})"
                }), 400

        # Deduct stock
        for item in items:
            cursor.execute("""
                UPDATE product_variations
                SET quantity = quantity - %s
                WHERE id = %s
            """, (item['cart_quantity'], item['variation_id']))

        total_amount = sum(float(item['price']) * item['cart_quantity'] for item in items)
        shipping_fee = 59.00

        # Insert order
        cursor.execute("""
            INSERT INTO orders (
                user_id, shipping_id, total_amount, payment_method,
                order_date, shipping_fee
            )
            VALUES (%s, %s, %s, %s, NOW(), %s)
        """, (user_id, shipping_id, total_amount + shipping_fee, payment_method, shipping_fee))
        order_id = cursor.lastrowid

        # Insert order items
        tracking_list = []
        for item in items:
            tracking_number = f"TRK-{item['product_id']}-{int(datetime.now().timestamp())}"
            cursor.execute("""
                INSERT INTO order_items (
                    order_id, product_id, product_variation_id, quantity,
                    size, price, order_status, color, shipping_fee, tracking_number
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                order_id, item['product_id'], item['variation_id'], item['cart_quantity'],
                item['size'], item['price'], 'Pending', item['color'], shipping_fee, tracking_number
            ))
            tracking_list.append({
                'product_id': item['product_id'],
                'tracking_number': tracking_number
            })

        # Remove items from cart
        delete_query = f"DELETE FROM cart WHERE user_id = %s AND cart_id IN ({placeholders})"
        cursor.execute(delete_query, [user_id] + cart_ids)

        db.commit()

        return jsonify({
            'status': 'success',
            'message': 'Order placed successfully',
            'trackings': tracking_list
        }), 200

    except Exception as e:
        print('[Checkout Error]:', e)
        return jsonify({'status': 'error', 'message': f'Server error: {str(e)}'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()
        
@app.route('/api/reject_order_item', methods=['POST'])
@cross_origin()
def reject_order_item():
    try:
        data = request.form
        order_item_id = data.get('order_item_id')

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor()

        cursor.execute("""
            UPDATE order_items
            SET rider_id = NULL, order_status = 'Pending'
            WHERE id = %s
        """, (order_item_id,))
        db.commit()

        return jsonify({'status': 'success', 'message': 'Order rejected successfully'}), 200

    except Exception as e:
        print('[Reject Error]:', e)
        return jsonify({'status': 'error', 'message': str(e)}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/get_shipping_address/<int:user_id>', methods=['GET'])
@cross_origin()
def get_shipping_address(user_id):
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # JOIN address with user info
        cursor.execute("""
            SELECT 
                a.region, a.province, a.city, a.barangay, a.street,
                u.first_name, u.last_name, u.contact_number
            FROM shipping_address a
            JOIN users u ON u.id = a.user_id
            WHERE a.user_id = %s
            ORDER BY a.id DESC LIMIT 1
        """, (user_id,))
        address = cursor.fetchone()

        if address:
            return jsonify({'status': 'success', 'address': address}), 200
        else:
            return jsonify({'status': 'error', 'message': 'Address not found'}), 404

    except Exception as e:
        print('[Address Error]:', e)
        return jsonify({'status': 'error', 'message': 'Database error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/user_profile/<int:user_id>', methods=['GET'])
@cross_origin()
def get_user_profile(user_id):
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                u.first_name, u.middle_name, u.last_name,
                pp.picture_url AS photo_url
            FROM users u
            LEFT JOIN profile_pictures pp ON u.id = pp.user_id
            WHERE u.id = %s
        """, (user_id,))
        user = cursor.fetchone()

        if user:
            return jsonify({'status': 'success', 'user': user}), 200
        else:
            return jsonify({'status': 'error', 'message': 'User not found'}), 404

    except Exception as e:
        print('[UserProfile Error]:', e)
        return jsonify({'status': 'error', 'message': 'Database error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/upload_profile_picture', methods=['POST'])
@cross_origin()
def upload_profile_picture():
    try:
        user_id = request.form.get('user_id')
        image = request.files.get('image')

        if not user_id or not image:
            return jsonify({'status': 'error', 'message': 'Missing user ID or image'}), 400

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Check existing image
        cursor.execute("SELECT picture_url FROM profile_pictures WHERE user_id = %s", (user_id,))
        old = cursor.fetchone()

        # Delete previous image if it exists
        if old and old['picture_url']:
            old_path = os.path.join('static', old['picture_url'].replace('\\', '/').split('/', 1)[-1])
            if os.path.exists(old_path):
                os.remove(old_path)

        # Save new image
        filename = f"{uuid.uuid4()}.jpg"
        save_path = os.path.join('static/profile_images', filename)
        os.makedirs(os.path.dirname(save_path), exist_ok=True)
        image.save(save_path)

        new_url = f"static/profile_images/{filename}"

        # Update or insert new image path
        cursor.execute("SELECT id FROM profile_pictures WHERE user_id = %s", (user_id,))
        if cursor.fetchone():
            cursor.execute(
                "UPDATE profile_pictures SET picture_url = %s WHERE user_id = %s",
                (new_url, user_id)
            )
        else:
            cursor.execute(
                "INSERT INTO profile_pictures (user_id, picture_url) VALUES (%s, %s)",
                (user_id, new_url)
            )

        db.commit()
        return jsonify({'status': 'success', 'message': 'Profile image updated', 'picture_url': new_url}), 200

    except Exception as e:
        print('[ProfileUpload Error]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/user_orders/<int:user_id>', methods=['GET'])
@cross_origin()
def get_user_orders_by_user(user_id):
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                oi.*, 
                o.user_id,
                p.name AS product_name, 
                p.image AS product_image,
                CONCAT(u.first_name, ' ', u.last_name) AS buyer_name
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            JOIN users u ON o.user_id = u.id
            JOIN products p ON oi.product_id = p.product_id
            WHERE o.user_id = %s
            ORDER BY oi.order_item_id DESC
        """, (user_id,))
        orders = cursor.fetchall()

        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print('[UserOrders Error]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/rider_login', methods=['POST'])
@cross_origin()
def rider_login_api():
    email = request.form.get('email')
    password = request.form.get('password')

    if not email or not password:
        return jsonify({'status': 'error', 'message': 'Email and password are required'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        query = "SELECT id FROM riders WHERE email = %s AND password = %s"
        cursor.execute(query, (email, password))
        rider = cursor.fetchone()

        if rider:
            return jsonify({'status': 'success', 'rider_id': rider['id']}), 200
        else:
            return jsonify({'status': 'error', 'message': 'Invalid email or password'}), 401

    except Exception as e:
        print('[RiderLogin Error]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/rider_active_orders', methods=['GET'])
@cross_origin()
def get_active_deliveries():
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                oi.order_item_id,
                oi.order_status,
                oi.size,
                oi.color,
                oi.price,
                oi.tracking_number,
                o.user_id,
                p.name AS product_name,
                p.image AS product_image
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            JOIN products p ON oi.product_id = p.product_id
            WHERE oi.order_status = 'To ship'
        """)
        orders = cursor.fetchall()
        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print('[ActiveOrders Error]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/rider_ongoing_orders', methods=['GET'])
@cross_origin()
def get_rider_ongoing_orders():
    rider_id = request.args.get('rider_id')

    if not rider_id:
        return jsonify({'status': 'error', 'message': 'Missing rider_id'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                oi.order_item_id,
                oi.order_status,
                oi.size,
                oi.color,
                oi.quantity,
                oi.price,
                p.name AS product_name,
                p.image AS product_image
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            WHERE oi.order_status = 'To Receive' AND oi.rider_id = %s
        """, (rider_id,))

        orders = cursor.fetchall()
        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print("[OngoingOrders Error]:", e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/order_item_details', methods=['GET'])
@cross_origin()
def get_order_item_details():
    order_item_id = request.args.get('order_item_id')

    if not order_item_id:
        return jsonify({'status': 'error', 'message': 'Missing order_item_id'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Step 1: Get order item details
        cursor.execute("""
            SELECT 
                oi.order_item_id,
                oi.order_status,
                oi.size,
                oi.color,
                oi.quantity,
                oi.price,
                oi.shipping_fee,
                p.name AS product_name,
                p.image AS product_image,
                o.order_id,
                o.user_id,
                o.shipping_id
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            JOIN products p ON oi.product_id = p.product_id
            WHERE oi.order_item_id = %s
        """, (order_item_id,))
        
        order_item = cursor.fetchone()
        if not order_item:
            return jsonify({'status': 'error', 'message': 'Order item not found'}), 404

        print("[ORDER ITEM]", order_item)

        user_id = order_item['user_id']
        shipping_id = order_item['shipping_id']

        # Step 2: Fallback — get most recent address if shipping_id is null
        if not shipping_id:
            cursor.execute("""
                SELECT id FROM shipping_address
                WHERE user_id = %s
                ORDER BY id DESC LIMIT 1
            """, (user_id,))
            fallback = cursor.fetchone()
            if fallback:
                shipping_id = fallback['id']
                print(f"[Fallback Shipping ID Used] {shipping_id}")
            else:
                print(f"[No shipping address found for user_id={user_id}]")

        # Step 3: Fetch recipient + address info if we now have a shipping_id
        if shipping_id:
            cursor.execute("""
                SELECT 
                    u.first_name,
                    u.middle_name,
                    u.last_name,
                    u.contact_number,
                    a.region,
                    a.province,
                    a.city,
                    a.barangay,
                    a.street
                FROM shipping_address a
                LEFT JOIN users u ON a.user_id = u.id
                WHERE a.id = %s
            """, (shipping_id,))
            recipient_data = cursor.fetchone() or {}
            print("[RECIPIENT DATA]", recipient_data)
            order_item.update(recipient_data)
        else:
            print("[SKIPPED address join] No valid shipping_id")

        print("[FINAL PAYLOAD]", order_item)
        return jsonify({'status': 'success', 'data': order_item}), 200

    except Exception as e:
        print("[OrderItemDetails ERROR]:", e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/save_rider_address', methods=['POST'])
@cross_origin()
def save_rider_address():
    try:
        data = request.get_json()
        rider_id = data.get('rider_id')
        street = data.get('street', '').strip()
        barangay = data.get('barangay', '').strip()
        city = data.get('city', '').strip()
        province = data.get('province', '').strip()
        region = data.get('region', '').strip()

        if not rider_id:
            return jsonify({'status': 'error', 'message': 'Missing rider_id'}), 400

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor()

        # Check if rider already has an address
        cursor.execute("SELECT id FROM rider_address WHERE rider_id = %s", (rider_id,))
        exists = cursor.fetchone()

        if exists:
            # Update existing address
            cursor.execute("""
                UPDATE rider_address
                SET street = %s,
                    barangay = %s,
                    city = %s,
                    province = %s,
                    region = %s,
                    updated_at = NOW()
                WHERE rider_id = %s
            """, (street, barangay, city, province, region, rider_id))
            message = 'Rider address updated'
        else:
            # Insert new address
            cursor.execute("""
                INSERT INTO rider_address (rider_id, street, barangay, city, province, region)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (rider_id, street, barangay, city, province, region))
            message = 'Rider address saved'

        db.commit()
        return jsonify({'status': 'success', 'message': message}), 200

    except Exception as e:
        print('[save_rider_address ERROR]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/get_rider_address', methods=['GET'])
@cross_origin()
def get_rider_address():
    rider_id = request.args.get('rider_id')

    if not rider_id:
        return jsonify({'status': 'error', 'message': 'Missing rider_id'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("SELECT * FROM rider_address WHERE rider_id = %s", (rider_id,))
        address = cursor.fetchone()

        if address:
            return jsonify({'status': 'success', 'address': address}), 200
        else:
            return jsonify({'status': 'error', 'message': 'No address found for this rider'}), 404

    except Exception as e:
        print('[get_rider_address ERROR]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/mark_delivered', methods=['POST'])
@cross_origin()
def mark_delivered():
    order_item_id = request.form.get('order_item_id')
    proof_image = request.files.get('proof_image')
    changed_by = request.form.get('changed_by', 'Rider')  # Optional field; fallback to "Rider"

    if not order_item_id or not proof_image:
        return jsonify({'status': 'error', 'message': 'Missing data'}), 400

    try:
        # Save image
        upload_folder = 'static/delivery_proofs'
        os.makedirs(upload_folder, exist_ok=True)

        filename = secure_filename(f"proof_{order_item_id}_{uuid.uuid4().hex}.jpg")
        filepath = os.path.join(upload_folder, filename)
        proof_image.save(filepath)

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Fetch product ID and quantity
        cursor.execute("""
            SELECT product_id, quantity
            FROM order_items
            WHERE order_item_id = %s
        """, (order_item_id,))
        item = cursor.fetchone()

        if not item:
            return jsonify({'status': 'error', 'message': 'Order item not found'}), 404

        product_id = item['product_id']
        quantity_delivered = item['quantity']

        # Deduct stock
        cursor.execute("""
            UPDATE products
            SET stock_quantity = stock_quantity - %s
            WHERE product_id = %s
        """, (quantity_delivered, product_id))

        # Update order_items
        cursor.execute("""
            UPDATE order_items
            SET order_status = 'Delivered',
                delivery_proof = %s,
                delivered_at = NOW(),
                status_changed_at = NOW()
            WHERE order_item_id = %s
        """, (filepath, order_item_id))

        # Log status change
        cursor.execute("""
            INSERT INTO order_status_log (order_item_id, status, changed_at, changed_by)
            VALUES (%s, 'Delivered', NOW(), %s)
        """, (order_item_id, changed_by))

        db.commit()
        return jsonify({'status': 'success', 'message': 'Order marked as delivered'}), 200

    except Exception as e:
        db.rollback()
        print("[mark_delivered Error]:", e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/rider_completed_orders', methods=['GET'])
@cross_origin()
def get_rider_completed_orders():
    rider_id = request.args.get('rider_id')

    if not rider_id:
        return jsonify({'status': 'error', 'message': 'Missing rider_id'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                oi.order_item_id,
                oi.order_status,
                oi.size,
                oi.color,
                oi.quantity,
                oi.price,
                p.name AS product_name,
                p.image AS product_image
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            WHERE oi.order_status = 'Delivered' AND oi.rider_id = %s
        """, (rider_id,))

        orders = cursor.fetchall()
        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print("[CompletedOrders Error]:", e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/rider_to_ship_orders', methods=['GET'])
@cross_origin()
def rider_to_ship_orders():
    rider_id = request.args.get('rider_id')

    if not rider_id:
        return jsonify({'status': 'error', 'message': 'Rider ID is required'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        query = """
            SELECT 
                oi.order_item_id, 
                oi.product_id, 
                oi.size, 
                oi.color, 
                oi.price, 
                oi.quantity,
                oi.order_status, 
                p.name AS product_name, 
                p.image AS product_image,
                osl.changed_at AS status_changed_at
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            LEFT JOIN (
                SELECT order_item_id, MAX(changed_at) AS changed_at
                FROM order_status_log
                WHERE status = 'Intransit'
                GROUP BY order_item_id
            ) osl ON oi.order_item_id = osl.order_item_id
            WHERE oi.order_status = 'Intransit' AND oi.rider_id = %s
        """
        cursor.execute(query, (rider_id,))
        orders = cursor.fetchall()

        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print('[ToShipOrders Error]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


@app.route('/api/rider_out_for_delivery_orders', methods=['GET'])
@cross_origin()
def rider_out_for_delivery_orders():
    rider_id = request.args.get('rider_id')

    if not rider_id:
        return jsonify({'status': 'error', 'message': 'Rider ID is required'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        query = """
            SELECT oi.order_item_id, oi.product_id, oi.size, oi.color, oi.price, oi.quantity,
                   oi.order_status, p.name AS product_name, p.image AS product_image
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            WHERE oi.order_status = 'Out for Delivery' AND oi.rider_id = %s
        """
        cursor.execute(query, (rider_id,))
        orders = cursor.fetchall()

        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print('[OutForDeliveryOrders Error]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/update_order_status', methods=['POST'])
@cross_origin()
def update_order_status_api():
    order_item_id = request.form.get('order_item_id')
    status = request.form.get('status')
    rider_id = request.form.get('rider_id')  # Optional
    changed_by = request.form.get('changed_by', 'System')  # Optional field or default to 'System'

    if not order_item_id or not status:
        return jsonify({'status': 'error', 'message': 'order_item_id and status are required'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor()

        # Update order_items
        if rider_id:
            update_query = """
                UPDATE order_items 
                SET order_status = %s, rider_id = %s, status_changed_at = NOW() 
                WHERE order_item_id = %s
            """
            cursor.execute(update_query, (status, rider_id, order_item_id))
        else:
            update_query = """
                UPDATE order_items 
                SET order_status = %s, status_changed_at = NOW() 
                WHERE order_item_id = %s
            """
            cursor.execute(update_query, (status, order_item_id))

        # Log the change to order_status_log
        log_query = """
            INSERT INTO order_status_log (order_item_id, status, changed_at, changed_by)
            VALUES (%s, %s, NOW(), %s)
        """
        cursor.execute(log_query, (order_item_id, status, changed_by))

        db.commit()
        return jsonify({'status': 'success', 'message': f'Order item updated to {status}'}), 200

    except Exception as e:
        db.rollback()
        print('[UpdateOrderStatus Error]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/rider_earnings', methods=['GET'])
@cross_origin()
def rider_earnings():
    rider_id = request.args.get('rider_id')

    if not rider_id:
        return jsonify({'status': 'error', 'message': 'Missing rider_id'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Fetch separate totals: one for (price * quantity), one for shipping_fee
        cursor.execute("""
            SELECT 
                SUM(price * quantity) AS total_product_value,
                SUM(shipping_fee) AS total_shipping_fee
            FROM order_items
            WHERE rider_id = %s AND order_status = 'Delivered'
        """, (rider_id,))
        result = cursor.fetchone()

        product_value = result['total_product_value'] or Decimal('0.0')
        shipping_fee = result['total_shipping_fee'] or Decimal('0.0')

        commission = (product_value * Decimal('0.10')).quantize(Decimal('0.01'))
        total_earnings = commission + shipping_fee

        return jsonify({
            'status': 'success',
            'commission': float(commission),
            'shipping_fee': float(shipping_fee),
            'earnings': float(total_earnings),
            'rate': "10% of product value + full shipping fee"
        }), 200

    except Exception as e:
        print("[RiderEarnings Error]:", e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/rider_earnings_breakdown', methods=['GET'])
@cross_origin()
def rider_earnings_breakdown():
    rider_id = request.args.get('rider_id')

    if not rider_id:
        return jsonify({'status': 'error', 'message': 'Missing rider_id'}), 400

    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Weekly and monthly earnings
        cursor.execute("""
            SELECT
                SUM(CASE 
                    WHEN WEEK(delivered_at, 1) = WEEK(NOW(), 1) AND YEAR(delivered_at) = YEAR(NOW())
                    THEN price * quantity ELSE 0 END) AS weekly_product,
                SUM(CASE 
                    WHEN WEEK(delivered_at, 1) = WEEK(NOW(), 1) AND YEAR(delivered_at) = YEAR(NOW())
                    THEN shipping_fee ELSE 0 END) AS weekly_shipping,
                
                SUM(CASE 
                    WHEN MONTH(delivered_at) = MONTH(NOW()) AND YEAR(delivered_at) = YEAR(NOW())
                    THEN price * quantity ELSE 0 END) AS monthly_product,
                SUM(CASE 
                    WHEN MONTH(delivered_at) = MONTH(NOW()) AND YEAR(delivered_at) = YEAR(NOW())
                    THEN shipping_fee ELSE 0 END) AS monthly_shipping
            FROM order_items
            WHERE rider_id = %s AND order_status = 'Delivered'
        """, (rider_id,))
        summary = cursor.fetchone()

        weekly_commission = (Decimal(summary['weekly_product'] or 0) * Decimal('0.10')).quantize(Decimal('0.01'))
        weekly_shipping = Decimal(summary['weekly_shipping'] or 0)
        monthly_commission = (Decimal(summary['monthly_product'] or 0) * Decimal('0.10')).quantize(Decimal('0.01'))
        monthly_shipping = Decimal(summary['monthly_shipping'] or 0)

        weekly_total = weekly_commission + weekly_shipping
        monthly_total = monthly_commission + monthly_shipping

        # Per-delivery breakdown
        cursor.execute("""
            SELECT
                oi.order_item_id,
                p.name AS product_name,
                oi.quantity,
                oi.shipping_fee,
                oi.price,
                oi.delivered_at
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            WHERE oi.rider_id = %s AND oi.order_status = 'Delivered'
            ORDER BY oi.delivered_at DESC
        """, (rider_id,))
        deliveries = cursor.fetchall()

        total_commission = Decimal('0.00')
        total_shipping = Decimal('0.00')

        # Add commission and shipping per item
        for d in deliveries:
            price = Decimal(str(d['price'] or 0))
            qty = d['quantity'] or 1
            fee = Decimal(str(d['shipping_fee'] or 0))

            product_value = price * qty
            commission = (product_value * Decimal('0.10')).quantize(Decimal('0.01'))
            earning = commission + fee

            d['commission'] = float(commission)
            d['earning'] = float(earning)

            total_commission += commission
            total_shipping += fee

        total_earnings = total_commission + total_shipping

        return jsonify({
            'status': 'success',
            'weekly': float(weekly_total),
            'monthly': float(monthly_total),
            'total_commission': float(total_commission),
            'total_shipping': float(total_shipping),
            'total_earnings': float(total_earnings),
            'deliveries': deliveries
        }), 200

    except Exception as e:
        print("[EarningsBreakdown Error]:", e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/order_tracking/<int:order_item_id>', methods=['GET'])
@cross_origin()
def get_order_tracking(order_item_id):
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                status,
                changed_at AS timestamp,
                changed_by
            FROM order_status_log
            WHERE order_item_id = %s
            ORDER BY changed_at DESC
        """, (order_item_id,))

        tracking = cursor.fetchall()

        return jsonify({'status': 'success', 'tracking': tracking}), 200

    except Exception as e:
        print("[Tracking API Error]:", e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/place_single_order', methods=['POST'])
@cross_origin()
def place_single_order():
    try:
        data = request.get_json()

        user_id = data.get('user_id')
        product_id = data.get('product_id')
        variation_id = data.get('variation_id')
        quantity = int(data.get('quantity', 1))
        payment_method = data.get('payment_method', 'cod')

        if not all([user_id, product_id, variation_id, quantity]):
            return jsonify({'status': 'error', 'message': 'Missing required fields'}), 400

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Get variation details
        cursor.execute("""
            SELECT price, size, color, quantity AS stock
            FROM product_variations
            WHERE id = %s AND product_id = %s
        """, (variation_id, product_id))
        variation = cursor.fetchone()

        if not variation:
            return jsonify({'status': 'error', 'message': 'Product variation not found'}), 404

        price = float(variation['price'])
        size = variation['size']
        color = variation['color']

        # Check stock availability
        if variation['stock'] < quantity:
            return jsonify({'status': 'error', 'message': 'Insufficient stock'}), 400

        # Insert into orders table
        total_amount = price * quantity
        cursor.execute("""
            INSERT INTO orders (user_id, shipping_id, total_amount, payment_method, order_date)
            VALUES (%s, %s, %s, %s, NOW())
        """, (user_id, None, total_amount, payment_method))
        order_id = cursor.lastrowid

        # Generate tracking number
        import uuid
        tracking_number = f'TRK-{uuid.uuid4().hex[:10].upper()}'

        # Insert into order_items
        cursor.execute("""
            INSERT INTO order_items (
                order_id, product_id, product_variation_id,
                quantity, size, color,
                price, order_status,
                tracking_number, status_changed_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
        """, (
            order_id, product_id, variation_id,
            quantity, size, color,
            price, 'Pending',
            tracking_number
        ))
        order_item_id = cursor.lastrowid

        # Log status
        cursor.execute("""
            INSERT INTO order_status_log (order_item_id, status, changed_at, changed_by)
            VALUES (%s, %s, NOW(), %s)
        """, (order_item_id, 'Pending', 'System'))

        db.commit()

        return jsonify({
            'status': 'success',
            'trackings': [{
                'product_id': product_id,
                'tracking_number': tracking_number
            }]
        }), 200

    except Exception as e:
        print('[place_single_order ERROR]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/submit_review', methods=['POST'])
@cross_origin()
def submit_review():
    try:
        order_item_id = request.form.get('order_item_id')
        rating = request.form.get('rating')
        review = request.form.get('review')
        file = request.files.get('media')

        if not all([order_item_id, rating, review]):
            return jsonify({'status': 'error', 'message': 'Missing fields'}), 400

        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        # Get product_id and user_id from order_item
        cursor.execute("""
            SELECT oi.product_id, o.user_id
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            WHERE oi.order_item_id = %s
        """, (order_item_id,))
        row = cursor.fetchone()

        if not row:
            return jsonify({'status': 'error', 'message': 'Invalid order_item_id'}), 400

        product_id = row['product_id']
        user_id = row['user_id']

        # Save media if provided
        media_url = None
        media_type = None

        if file:
            ext = os.path.splitext(file.filename)[1].lower()
            is_image = ext in ['.jpg', '.jpeg', '.png']
            is_video = ext in ['.mp4', '.mov', '.avi']

            if not (is_image or is_video):
                return jsonify({'status': 'error', 'message': 'Unsupported file type'}), 400

            media_type = 'image' if is_image else 'video'
            upload_folder = 'static/review_media'
            os.makedirs(upload_folder, exist_ok=True)

            filename = secure_filename(f'review_{order_item_id}_{uuid.uuid4().hex}{ext}')
            filepath = os.path.join(upload_folder, filename)
            file.save(filepath)
            media_url = f'{upload_folder}/{filename}'

        # Insert review
        cursor.execute("""
            INSERT INTO product_reviews (
                order_item_id, product_id, user_id,
                rating, review_text, media_url, media_type, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
        """, (order_item_id, product_id, user_id, rating, review, media_url, media_type))

        db.commit()
        return jsonify({'status': 'success'}), 200

    except Exception as e:
        print('[submit_review ERROR]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/api/product_reviews/<int:product_id>', methods=['GET'])
@cross_origin()
def get_product_reviews(product_id):
    try:
        db = mysql.connector.connect(**db_config)
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT rating, review_text, media_url, media_type, created_at
            FROM product_reviews
            WHERE product_id = %s
            ORDER BY created_at DESC
        """, (product_id,))
        reviews = cursor.fetchall()

        return jsonify({'status': 'success', 'reviews': reviews}), 200

    except Exception as e:
        print('[get_product_reviews ERROR]:', e)
        return jsonify({'status': 'error', 'message': 'Server error'}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/seller')
def seller_homepage():
    # Ensure the user is logged in and is a seller
    if 'user_id' not in session or session['role'] != 'seller':
        return redirect(url_for('login'))  # Redirect to login page if not logged in or not a seller

    seller_id = session['user_id']  # Get the logged-in seller's user ID

    # Define the function to get total sales for the seller (only delivered orders)
    def get_total_sales(seller_id):
        with db.cursor(dictionary=True) as cursor:
            cursor.execute("""
                SELECT COALESCE(SUM(o.total_amount), 0) AS total_sales
                FROM orders o
                JOIN order_items oi ON o.order_id = oi.order_id
                JOIN products p ON oi.product_id = p.product_id
                WHERE p.seller_id = %s
                AND oi.order_status = 'Delivered'  -- Only count delivered orders
            """, (seller_id,))
            result = cursor.fetchone()
        return result['total_sales']

    # Define the function to get total products for the seller
    def get_total_products(seller_id):
        with db.cursor(dictionary=True) as cursor:
            cursor.execute("""
                SELECT COUNT(*) AS total_products
                FROM products
                WHERE seller_id = %s
            """, (seller_id,))
            result = cursor.fetchone()
        return result['total_products']

    # Define the function to get total orders for the seller
    def get_total_orders(seller_id):
        with db.cursor(dictionary=True) as cursor:
            cursor.execute("""
                SELECT COUNT(DISTINCT oi.order_id) AS total_orders
                FROM order_items oi
                JOIN products p ON oi.product_id = p.product_id
                WHERE p.seller_id = %s
            """, (seller_id,))
            result = cursor.fetchone()
        return result['total_orders']

    # Fetch the data for the logged-in seller
    total_sales = get_total_sales(seller_id)
    total_products = get_total_products(seller_id)
    total_orders = get_total_orders(seller_id)

    # Ensure both total_sales and commission_rate are Decimal
    commission_rate = Decimal('0.1')  # Example commission rate (10%)
    total_commission = Decimal(str(total_sales)) * commission_rate  # Calculate commission

    # Fetch the products for the seller to display them
    with db.cursor(dictionary=True) as cursor:
        cursor.execute("""
            SELECT product_id, name, price, stock_quantity
            FROM products
            WHERE seller_id = %s
        """, (seller_id,))
        products = cursor.fetchall()

    # Fetch the list of buyers that the seller has interacted with
    with db.cursor(dictionary=True) as cursor:
        cursor.execute("""
            SELECT DISTINCT u.id AS buyer_id, u.first_name AS buyer_name
            FROM messages m
            JOIN users u ON u.id = m.sender_id OR u.id = m.receiver_id
            WHERE (m.sender_id = %s OR m.receiver_id = %s) AND u.role = 'buyer'
        """, (seller_id, seller_id))
        buyer_chats = cursor.fetchall()

    # Render the template with the data specific to the seller
    return render_template('seller_homepage.html', 
                           total_sales=total_sales, 
                           total_products=total_products, 
                           total_orders=total_orders, 
                           products=products, 
                           total_commission=total_commission,
                           buyer_chats=buyer_chats)


@app.route('/cart/count')
def cart_count():
    if 'user_id' not in session:
        return {'count': 0}  # If user is not logged in, return 0

    user_id = session['user_id']

    # Establish a connection to the database
    connection = mysql.connector.connect(
        host="localhost",  # Your MySQL host
        user="root",       # Your MySQL user
        password="",       # Your MySQL password
        database="fara"    # Your database name
    )
    
    cursor = connection.cursor()

    try:
        # Count the number of distinct products in the user's cart
        cursor.execute("SELECT COUNT(*) FROM cart WHERE user_id = %s", (user_id,))
        total_items = cursor.fetchone()[0]

        return {'count': total_items}
    
    except mysql.connector.Error as err:
        # Handle errors (e.g., connection failure, query issues)
        return {'count': 0, 'message': str(err)}

    finally:
        # Ensure the connection is closed to avoid memory leaks
        cursor.close()
        connection.close()

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        # Connect to the database
        db = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",  # replace with your actual password
            database="fara"  # replace with your actual database name
        )
        
        cursor = db.cursor(dictionary=True)
        
        try:
            # Retrieve user data including password, status, and role
            cursor.execute("SELECT id, password, status, role FROM users WHERE email = %s", (email,))
            user = cursor.fetchone()

            if user:
                # Check if the account is active
                if user['status'] != 'active':
                    flash('Your account is not active. Please contact support or check your email for activation instructions.', 'error')
                    return redirect(url_for('login'))
                
                # If the account is active, check the plain-text password
                if user['password'] == password:  # Compare plain-text passwords
                    # Store the user ID and role in the session
                    session['user_id'] = user['id']
                    session['role'] = user['role']

                    # Flash a success message and redirect based on the user's role
                    flash('Login successful!', 'success')
                    if user['role'] == 'buyer':
                        return redirect(url_for('buyer_homepage'))
                    elif user['role'] == 'seller':
                        return redirect(url_for('seller_homepage'))
                    elif user['role'] == 'admin':
                        return redirect(url_for('admin_dashboard'))
                else:
                    flash('Invalid credentials. Please try again.', 'error')
                    return redirect(url_for('login'))
            else:
                flash('Invalid email or password. Please try again.', 'error')
                return redirect(url_for('login'))

        finally:
            cursor.close()
            db.close()

    return render_template('login.html')

#========================================flutter==========================================
@app.route('/api/login', methods=['POST'])
def login_api():
    data = request.form or request.get_json()

    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'status': 'error', 'message': 'Email and password are required'}), 400

    db = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="fara"
    )
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute("SELECT id, password, status, role FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()
    finally:
        cursor.close()
        db.close()

    if user:
        if user['status'] != 'active':
            return jsonify({'status': 'error', 'message': 'Account not active'}), 403

        if user['password'] == password:
            return jsonify({
                'status': 'success',
                'role': user['role'],
                'user_id': user['id']
            }), 200

        return jsonify({'status': 'error', 'message': 'Invalid credentials'}), 401

    return jsonify({'status': 'error', 'message': 'User not found'}), 404

@app.route('/logout')
def logout():
    session.pop('user_id', None)  # Remove user ID from the session
    session.pop('role', None)      # Remove role from the session
    flash('You have been logged out successfully.')  # Optional flash message
    return redirect(url_for('home'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        # Collect form data
        first_name = request.form['first_name'].strip()
        last_name = request.form['last_name'].strip()
        middle_name = request.form.get('middle_name', '').strip()
        contact_number = request.form['contact_number'].strip()
        birthday = request.form['birthday'].strip()
        email = request.form['email'].strip()
        password = request.form['password'].strip()
        role = request.form['role'].strip()

        # Validate contact number
        if not contact_number.startswith('09'):
            flash('Contact number must start with 09.', 'error')
            return redirect(url_for('register'))
        if len(contact_number) != 11 or not contact_number.isdigit():
            flash('Contact number must be exactly 11 digits long and contain only digits.', 'error')
            return redirect(url_for('register'))

        # Validate birthday and calculate age
        try:
            birthday_date = datetime.strptime(birthday, '%Y-%m-%d')
            age = compute_age(birthday_date)
        except ValueError:
            flash('Invalid birthday format. Please use YYYY-MM-DD.', 'error')
            return redirect(url_for('register'))

        # Handle photo upload
        if 'photo' not in request.files:
            return 'No file part', 400
        file = request.files['photo']
        if file.filename == '':
            return 'No selected file', 400
        if not allowed_file(file.filename):
            return 'File type not allowed', 400

        # Secure the filename and create a unique name
        original_filename = secure_filename(file.filename)
        file_extension = os.path.splitext(original_filename)[1]  # Get the file extension
        unique_filename = f"{uuid.uuid4()}{file_extension}"  # Generate a unique filename
        photo_path = os.path.join(app.config['ID_FOlDER'], unique_filename)

        # Save the file to the designated path
        file.save(photo_path)

        # Save only the relative path in the database
        relative_photo_path = f'IDs/{unique_filename}' 

        # Check if email already exists
        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        existing_user = cursor.fetchone()
        if existing_user:
            flash('Email is already registered. Please use a different email.', 'error')
            return redirect(url_for('register'))

        # Store user data temporarily in session
        session['user_data'] = {
            'first_name': first_name,
            'last_name': last_name,
            'middle_name': middle_name,
            'contact_number': contact_number,
            'birthday': birthday,
            'email': email,
            'password': password,
            'role': role,
            'photo': relative_photo_path,
            'age': age
        }

        # Generate OTP and store it in session
        otp = random.randint(100000, 999999)
        session['otp'] = otp

        # Send OTP to email
        if send_otp(email, otp):
            flash('An OTP has been sent to your email. Please check your inbox.', 'success')
            
            # If the user is a seller, redirect to seller registration form
            if role == 'seller':
                return redirect(url_for('seller_register'))  # Redirect to seller-specific form
                
            return redirect(url_for('address'))  # Redirect to address form for buyers

        else:
            flash('Failed to send OTP. Please try again.', 'error')
            return redirect(url_for('register'))

    return render_template('register.html')

@app.route('/seller-register', methods=['GET', 'POST'])
def seller_register():
    if request.method == 'POST':
        # Collect seller-specific form data
        shop_name = request.form['shop_name'].strip()

        # Handle shop image upload (if applicable)
        if 'shop_image' not in request.files:
            return 'No file part', 400
        file = request.files['shop_image']
        if file.filename == '':
            return 'No selected file', 400
        if not allowed_file(file.filename):
            return 'File type not allowed', 400

        # Secure the filename and create a unique name for the shop image
        original_filename = secure_filename(file.filename)
        file_extension = os.path.splitext(original_filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        shop_image_path = os.path.join(app.config['SHOP_IMAGE_FOLDER'], unique_filename)

        # Save the shop image
        file.save(shop_image_path)

        # Store only the relative path in the database
        relative_shop_image_path = f'shop_images/{unique_filename}'

        # Store the seller's shop details in session
        session['seller_data'] = {
            'shop_name': shop_name,
            'shop_image': relative_shop_image_path
        }

        # Generate OTP and store it in the session
        otp = random.randint(100000, 999999)
        session['otp'] = otp

        # Send OTP to email
        if send_otp(session['user_data']['email'], otp):
            flash('An OTP has been sent to your email. Please check your inbox.', 'success')
            return redirect(url_for('verify_otp'))  # Redirect to OTP verification page
        else:
            flash('Failed to send OTP. Please try again.', 'error')
            return redirect(url_for('seller_register'))

    return render_template('seller_register.html')

@app.route('/address', methods=['GET', 'POST'])
def address():
    if request.method == 'POST':
        try:
            # Check if the request is JSON or Form data
            if request.is_json:
                data = request.get_json()
            else:
                data = request.form

            # Log the received data for debugging
            app.logger.info(f"Received address data: {data}")

            # Extract address components from the data
            region_name = data.get('region')
            province_name = data.get('province')
            city_name = data.get('city')
            barangay_name = data.get('barangay')
            street_name = data.get('street', '')  # Optional field

            # Validate required fields
            if not region_name or not province_name or not city_name or not barangay_name:
                app.logger.error("Missing required address fields.")  # Log error
                return jsonify({"success": False, "message": "All required address fields (region, province, city, barangay) must be filled."}), 400

            # Retrieve user session data
            user_data = session.get('user_data')
            if not user_data:
                app.logger.error("Session expired or no user data found.")  # Log error
                return jsonify({"success": False, "message": "Session expired. Please log in again."}), 400

            # Check if the user data contains valid fields
            app.logger.info(f"User session data: {user_data}")  # Log session data
            if 'first_name' not in user_data or 'last_name' not in user_data:
                app.logger.error("User data is incomplete in the session.")  # Log error
                return jsonify({"success": False, "message": "User data is incomplete. Please log in again."}), 400

            # Save address data in session
            user_data['address'] = {
                'region': region_name,
                'province': province_name,
                'city': city_name,
                'barangay': barangay_name,
                'street': street_name,  # Store the street value (optional)
            }
            session['user_data'] = user_data

            app.logger.info(f"Address data saved to session: {user_data['address']}")  # Log address data saved

            # Return a JSON response indicating success
            return jsonify({"success": True, "message": "Address saved successfully!"}), 200

        except Exception as e:
            # Log the error message for debugging
            app.logger.error(f"Error while saving address: {e}")
            return jsonify({"success": False, "message": f"An unexpected error occurred: {e}"}), 500

    # Handle GET request to display the form with existing data (if any)
    user_data = session.get('user_data')
    if user_data and 'address' in user_data:
        address_data = user_data['address']
        app.logger.info(f"Returning saved address data: {address_data}")  # Log address data being returned
    else:
        address_data = {}
        app.logger.info("No address data found in session.")  # Log when no address is found

    # Return a valid response for GET request
    return render_template('address.html', address_data=address_data)


@app.route('/verify_otp', methods=['GET', 'POST'])
def verify_otp():
    if request.method == 'POST':
        user_otp = request.form.get('otp', '').strip()
        stored_otp = session.get('otp')

        # Check if the OTP matches
        if not stored_otp or str(user_otp) != str(stored_otp):
            flash('Invalid or expired OTP. Please try again.', 'error')
            return redirect(url_for('verify_otp'))

        # Retrieve user data and address data from session
        user_data = session.get('user_data')
        if not user_data:
            flash("Session expired. Please log in again.", "error")
            return redirect(url_for('login'))

        # Retrieve address data and seller-specific data (shop name and shop image)
        address_data = user_data.get('address', {})
        seller_data = session.get('seller_data', {})
        shop_name = seller_data.get('shop_name')
        shop_image = seller_data.get('shop_image')

        try:
            # Insert user data into the `users` table (without password hashing)
            cursor = db.cursor()
            cursor.execute(""" 
                INSERT INTO users (first_name, last_name, middle_name, contact_number, birthday, email, password, role, photo, age, status) 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'pending')
            """, (
                user_data['first_name'], user_data['last_name'], user_data['middle_name'],
                user_data['contact_number'], user_data['birthday'], user_data['email'],
                user_data['password'], user_data['role'], user_data['photo'], user_data['age']
            ))

            # Retrieve the user ID of the newly inserted user
            cursor.execute("SELECT LAST_INSERT_ID()")
            user_id = cursor.fetchone()[0]

            # If the user is a buyer, insert address data into the `shipping_address` table
            if user_data['role'] == 'buyer':
                cursor.execute(""" 
                    INSERT INTO shipping_address (user_id, region, province, city, barangay, street) 
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    user_id,
                    address_data.get('region'), address_data.get('province'), address_data.get('city'),
                    address_data.get('barangay'), address_data.get('street', '')  # Optional field
                ))

            # If the user is a seller, store shop information in `seller_shops`
            elif user_data['role'] == 'seller' and shop_name:
                cursor.execute("""
                    INSERT INTO seller_shops (user_id, shop_name, shop_image)
                    VALUES (%s, %s, %s)
                """, (user_id, shop_name, shop_image))

            # Commit all insertions together
            db.commit()

            # Clear session data to avoid reuse
            session.pop('user_data', None)
            session.pop('otp', None)
            session.pop('seller_data', None)  # Clear seller-specific data

            flash('Registration successful! You can now log in.', 'success')
            return redirect(url_for('login'))

        except mysql.connector.Error as e:
            db.rollback()
            flash(f"Database error: {e}", 'error')
            return redirect(url_for('verify_otp'))

    return render_template('verify_otp.html')


@app.route('/buyer/dashboard', methods=['GET', 'POST'])
def buyer_dashboard():
    if 'user_id' not in session or session['role'] != 'buyer':
        return 'Unauthorized access', 403

    search_query = None
    if request.method == 'POST':
        search_query = request.form.get('search')  # Get the search term from the form

    # Fetch products with search query (if any)
    products = fetch_products(search_query)
    return render_template('buyer_dashboard.html', products=products, search_query=search_query)


@app.route('/category/<category_name>')
def category_products(category_name):
    if 'user_id' not in session or session['role'] != 'buyer':
        return 'Unauthorized access', 403
    
    # Open a database connection
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="fara"
    )

    # Create a cursor object to execute queries
    cursor = connection.cursor()

    try:
        # Execute the query to get products by category
        cursor.execute('SELECT * FROM products WHERE category = %s', (category_name,))
        products = cursor.fetchall()  # Fetch all results

        # Render the template with the filtered products by category
        return render_template('buyer_dashboard.html', products=products)

    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return 'Database error', 500
    
    finally:
        # Make sure to close the cursor and the connection
        cursor.close()
        connection.close()


@app.route('/seller/dashboard', methods=['GET'])
def seller_dashboard():
    if 'user_id' not in session or session['role'] != 'seller':
        return redirect(url_for('login'))

    cursor = db.cursor()
    
    # Fetch products belonging to the seller
    cursor.execute("SELECT * FROM products WHERE seller_id = %s", (session['user_id'],))
    products = cursor.fetchall()
    
    cursor.close()
    return render_template('seller_dashboard.html', products=products)


from decimal import Decimal

@app.route('/admin/dashboard', methods=['GET'])
def admin_dashboard():
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    cursor = db.cursor(dictionary=True)

    # Fetch total sales (sum of total_amount from orders where all items are 'Delivered')
    cursor.execute("""
        SELECT COALESCE(SUM(o.total_amount), 0) AS total_sales
        FROM orders o
        WHERE EXISTS (
            SELECT 1 
            FROM order_items oi 
            WHERE oi.order_id = o.order_id AND oi.order_status = 'Delivered'
        )
    """)
    total_sales = cursor.fetchone()['total_sales']
    total_sales = Decimal(str(total_sales))  # Convert to Decimal to avoid float issues

    # Fetch total commission (example: total sales * some commission rate, adjust as needed)
    commission_rate = 0.1  # Example commission rate (10%)
    total_commission = total_sales * Decimal(str(commission_rate))  # Ensure both are Decimal

    # Fetch total products
    cursor.execute("SELECT COUNT(*) AS total_products FROM products")
    total_products = cursor.fetchone()['total_products']

    # Fetch total sellers (users with 'seller' role)
    cursor.execute("SELECT COUNT(*) AS total_sellers FROM users WHERE role = 'seller'")
    total_sellers = cursor.fetchone()['total_sellers']

    # Fetch total buyers (users with 'buyer' role)
    cursor.execute("SELECT COUNT(*) AS total_buyers FROM users WHERE role = 'buyer'")
    total_buyers = cursor.fetchone()['total_buyers']

    # Fetch recent orders (limiting to recent 5 orders for display)
    cursor.execute("""
        SELECT o.order_id, o.total_amount, o.payment_method, o.order_date, u.first_name AS user_name
        FROM orders o
        JOIN users u ON o.user_id = u.id
        ORDER BY o.order_date DESC LIMIT 5
    """)
    recent_orders = cursor.fetchall()

    # Fetch recent customers (limiting to recent 5 customers for display)
    cursor.execute("""
        SELECT id, first_name, email
        FROM users
        ORDER BY id DESC LIMIT 5
    """)
    recent_customers = cursor.fetchall()

    cursor.close()

    return render_template(
        'admin_dashboard.html', 
        total_sales=total_sales, 
        total_commission=total_commission,
        total_products=total_products,
        total_sellers=total_sellers,
        total_buyers=total_buyers,
        recent_orders=recent_orders,
        recent_customers=recent_customers
    )


    

@app.route('/admin/users')
def view_users():
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    return render_template('admin_users.html', users=users)

#seller add product
@app.route('/add_product', methods=['GET', 'POST'])
def add_product():
    if 'user_id' not in session or session['role'] != 'seller':
        return redirect(url_for('login'))
    
    if request.method == 'POST':
        name = request.form['name']
        description = request.form['description']
        price = request.form['price']
        category = request.form['category']

        # Handle main product image upload
        if 'image' not in request.files:
            return 'No file part', 400
        
        file = request.files['image']
        if file.filename == '':
            return 'No selected file', 400
        
        if not allowed_file(file.filename):
            return 'File type not allowed', 400

        # Secure the filename and create a unique name
        original_filename = secure_filename(file.filename)
        file_extension = os.path.splitext(original_filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        image_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
        file.save(image_path)
        relative_image_path = f'uploads/{unique_filename}'

        # Gather variation data
        sizes = request.form.getlist('variation_size[]')
        colors = request.form.getlist('variation_color[]')
        quantities = request.form.getlist('variation_quantity[]')
        prices = request.form.getlist('variation_price[]')  # New: gather prices for each variation
        variation_images = request.files.getlist('variation_image[]')

        # Calculate total stock quantity
        total_stock_quantity = sum(int(q) for q in quantities)

        # Insert main product into database
        cursor = db.cursor()
        sql = """
        INSERT INTO products (seller_id, name, description, price, category, stock_quantity, image)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (session['user_id'], name, description, price, category, total_stock_quantity, relative_image_path))
        product_id = cursor.lastrowid  # Get the new product's ID

        # Handle variations
        for size, color, quantity, variation_price, variation_file in zip(sizes, colors, quantities, prices, variation_images):
            # Process optional variation image
            if variation_file and variation_file.filename:
                if allowed_file(variation_file.filename):
                    variation_filename = secure_filename(variation_file.filename)
                    variation_extension = os.path.splitext(variation_filename)[1]
                    unique_variation_filename = f"{uuid.uuid4()}{variation_extension}"
                    variation_image_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_variation_filename)
                    variation_file.save(variation_image_path)
                    relative_variation_image_path = f'uploads/{unique_variation_filename}'
                else:
                    return 'File type not allowed for variation image', 400
            else:
                relative_variation_image_path = None  # No image uploaded for this variation

            # Insert variation into the database, including the variation price
            variation_sql = """
            INSERT INTO product_variations (product_id, size, color, quantity, price, image_path)
            VALUES (%s, %s, %s, %s, %s, %s)
            """
            cursor.execute(variation_sql, (product_id, size, color, quantity, variation_price, relative_variation_image_path))

        db.commit()
        cursor.close()
        
        return redirect(url_for('seller_dashboard'))

    return render_template('add_product.html')


@app.route('/edit_product/<int:product_id>', methods=['GET', 'POST'])
def edit_product(product_id):
    if 'user_id' not in session or session['role'] != 'seller':
        return redirect(url_for('login'))

    cursor = db.cursor()

    if request.method == 'POST':
        name = request.form['name']
        description = request.form['description']
        price = request.form['price']
        category = request.form['category']
        sizes = request.form.getlist('variation_size[]')
        colors = request.form.getlist('variation_color[]')
        quantities = request.form.getlist('variation_quantity[]')
        prices = request.form.getlist('variation_price[]')  # Get the price for each variation
        variation_images = request.files.getlist('variation_image[]')

        # Update the product info
        cursor.execute("""
            UPDATE products 
            SET name = %s, description = %s, price = %s, category = %s 
            WHERE product_id = %s AND seller_id = %s
        """, (name, description, price, category, product_id, session['user_id']))

        # Update variations
        cursor.execute("DELETE FROM product_variations WHERE product_id = %s", (product_id,))
        total_stock_quantity = 0  # Initialize total stock quantity

        for size, color, quantity, variation_price, variation_file in zip(sizes, colors, quantities, prices, variation_images):
            # Find the existing variation image for this size/color if no new image is provided
            relative_variation_image_path = None

            if variation_file and variation_file.filename:
                # If a new image is uploaded, save it
                if allowed_file(variation_file.filename):  # Check if the file is allowed
                    variation_filename = secure_filename(variation_file.filename)
                    unique_variation_filename = f"{uuid.uuid4()}{os.path.splitext(variation_filename)[1]}"
                    variation_image_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_variation_filename)
                    variation_file.save(variation_image_path)
                    relative_variation_image_path = f'uploads/{unique_variation_filename}'
            else:
                # If no new image is uploaded, keep the existing image
                cursor.execute("""
                    SELECT image_path 
                    FROM product_variations 
                    WHERE product_id = %s AND size = %s AND color = %s
                """, (product_id, size, color))
                existing_image = cursor.fetchone()
                if existing_image:
                    relative_variation_image_path = existing_image[0]  # Use the existing image path

            # Insert the variation record with updated or unchanged image path and price
            cursor.execute("""
                INSERT INTO product_variations (product_id, size, color, quantity, price, image_path)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (product_id, size, color, quantity, variation_price, relative_variation_image_path))

            total_stock_quantity += int(quantity)  # Add the quantity to the total stock

        # Update the product's total stock quantity
        cursor.execute("""
            UPDATE products 
            SET stock_quantity = %s 
            WHERE product_id = %s
        """, (total_stock_quantity, product_id))

        db.commit()
        cursor.close()

        return redirect(url_for('seller_dashboard'))
    
    # Retrieve product details for displaying in the form
    cursor.execute("SELECT * FROM products WHERE product_id = %s AND seller_id = %s", (product_id, session['user_id']))
    product = cursor.fetchone()

    # Retrieve variations for the product
    cursor.execute("SELECT * FROM product_variations WHERE product_id = %s", (product_id,))
    variations = cursor.fetchall()

    cursor.close()
    return render_template('edit_product.html', product=product, variations=variations)

@app.route('/product/<int:product_id>', methods=['GET'])
def product_detail(product_id):
    cursor = db.cursor(dictionary=True)
    
    # Fetch product details, including seller_id
    cursor.execute("""
        SELECT 
            products.product_id, 
            products.name, 
            products.description, 
            products.price, 
            products.image AS image_path, 
            products.stock_quantity, 
            products.seller_id,  -- Ensure seller_id is fetched
            users.first_name, 
            users.last_name
        FROM products 
        JOIN users ON products.seller_id = users.id
        WHERE products.product_id = %s
    """, (product_id,))
    product = cursor.fetchone()

    if not product:
        flash('Product not found.')
        return redirect(url_for('buyer_homepage'))

    # Fetch product variations (size, color, image, price, and stock_quantity)
    cursor.execute("""
        SELECT size, color, image_path, price, quantity
        FROM product_variations
        WHERE product_id = %s
    """, (product_id,))
    variations = cursor.fetchall()

    # Get available sizes and colors separately
    sizes = {variation['size'] for variation in variations}
    colors = {variation['color'] for variation in variations}

    # Add variations, sizes, colors, and stock quantities to the product data
    product['variations'] = variations
    product['sizes'] = list(sizes)
    product['colors'] = list(colors)

    # Pass product with variations, sizes, colors, and stock quantities to template
    return render_template('product_detail.html', product=product)


from decimal import Decimal
import json
from flask import render_template, request, session, redirect, url_for, flash, jsonify

@app.route('/cart', methods=['GET'])
def cart():
    if 'user_id' not in session:
        flash('You need to be logged in to view your cart.')
        return redirect(url_for('login'))

    user_id = session['user_id']
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT c.cart_id, p.product_id, p.name, c.quantity, c.size, c.color, c.price, c.image_path,
                   COALESCE(pv.quantity, 0) AS available_quantity,
                   (
                       SELECT GROUP_CONCAT(DISTINCT size ORDER BY size)
                       FROM product_variations
                       WHERE product_id = c.product_id
                   ) AS available_sizes,
                   (
                       SELECT GROUP_CONCAT(DISTINCT color ORDER BY color)
                       FROM product_variations
                       WHERE product_id = c.product_id
                   ) AS available_colors,
                   (
                       SELECT GROUP_CONCAT(price ORDER BY size)
                       FROM product_variations
                       WHERE product_id = c.product_id
                   ) AS variation_prices,
                   (
                       SELECT GROUP_CONCAT(quantity ORDER BY size)
                       FROM product_variations
                       WHERE product_id = c.product_id
                   ) AS variation_quantities
            FROM cart c
            JOIN products p ON c.product_id = p.product_id
            LEFT JOIN product_variations pv ON c.product_id = pv.product_id AND c.size = pv.size AND c.color = pv.color
            WHERE c.user_id = %s
        """, (user_id,))
        cart_items = cursor.fetchall()
    except Exception as e:
        flash("An error occurred while fetching your cart. Please try again later.")
        return redirect(url_for('home'))

    total = Decimal(0)

    for item in cart_items:
        # Start with base product price
        selected_price = Decimal(item['price'])
        available_quantity = int(item['available_quantity']) if item['available_quantity'] else 0

        sizes = item['available_sizes'].split(',') if item['available_sizes'] else []
        colors = item['available_colors'].split(',') if item['available_colors'] else []
        variation_prices = item['variation_prices'].split(',') if item['variation_prices'] else []
        variation_quantities = item['variation_quantities'].split(',') if item['variation_quantities'] else []

        # Default quantity available
        available_quantity_for_this_variation = available_quantity
        variation_found = False

        if sizes and variation_prices:
            for i in range(len(sizes)):
                if sizes[i] == item['size']:
                    selected_price = Decimal(variation_prices[i])
                    if i < len(variation_quantities):
                        available_quantity_for_this_variation = int(variation_quantities[i])
                    variation_found = True
                    break

        if not variation_found:
            selected_price = Decimal(item['price'])  # fallback price

        # Notify user if overstocked (but don't forcibly reduce here)
        if item['quantity'] > available_quantity_for_this_variation:
            flash(f'You have more of "{item["name"]}" in your cart than available. Please reduce to {available_quantity_for_this_variation}.')

        # Add to total
        total += selected_price * Decimal(item['quantity'])

        # Frontend variation JSON
        item['variations_json'] = json.dumps([
            {
                'size': sizes[i] if i < len(sizes) else '',
                'color': colors[i] if i < len(colors) else '',
                'price': variation_prices[i] if i < len(variation_prices) else '',
                'quantity': variation_quantities[i] if i < len(variation_quantities) else ''
            }
            for i in range(len(sizes))
        ])

    cursor.close()
    return render_template('cart.html', cart_items=cart_items, total=total)


@app.route('/update_cart_quantity', methods=['POST'])
def update_cart_quantity():
    if 'user_id' not in session:
        return jsonify({'success': False, 'message': 'User not logged in'}), 403

    data = request.get_json()
    cart_id = data.get('cart_id')
    new_quantity = data.get('quantity')

    if not cart_id or not isinstance(new_quantity, int) or new_quantity < 1:
        return jsonify({'success': False, 'message': 'Invalid input'}), 400

    cursor = db.cursor()
    try:
        cursor.execute("""
            UPDATE cart
            SET quantity = %s
            WHERE cart_id = %s AND user_id = %s
        """, (new_quantity, cart_id, session['user_id']))
        db.commit()
    except Exception as e:
        db.rollback()
        return jsonify({'success': False, 'message': 'Database update failed'})
    finally:
        cursor.close()

    return jsonify({'success': True})

@app.route('/add_to_cart/<int:product_id>', methods=['POST'])
def add_to_cart(product_id):
    if 'user_id' not in session:
        flash('You need to be logged in to add items to your cart.')
        return redirect(url_for('login'))  # Redirect to login if user is not logged in

    # Get quantity, size, and color from the form
    quantity = request.form.get('quantity', type=int)
    size = request.form.get('size')
    color = request.form.get('color')

    # Validate quantity, size, and color
    if quantity is None or quantity <= 0:
        flash('Invalid quantity. Quantity must be a positive number.')
        return redirect(url_for('product_detail', product_id=product_id))

    if not size:
        flash('Please select a size.')
        return redirect(url_for('product_detail', product_id=product_id))

    if not color:
        flash('Please select a color.')
        return redirect(url_for('product_detail', product_id=product_id))

    # Use a dictionary cursor to get results as dictionaries instead of tuples
    cursor = db.cursor(dictionary=True)

    # Retrieve product details, including base price and available variations
    cursor.execute("""
        SELECT p.price AS base_price, pv.price AS variation_price, pv.image_path, pv.quantity AS available_quantity
        FROM products p
        LEFT JOIN product_variations pv ON p.product_id = pv.product_id AND pv.size = %s AND pv.color = %s
        WHERE p.product_id = %s
    """, (size, color, product_id))
    product = cursor.fetchone()

    if not product:
        flash('Product not found.')
        return redirect(url_for('product_detail', product_id=product_id))

    # Retrieve the price and variation details from the dictionary result
    product_price = product['variation_price'] if product['variation_price'] else product['base_price']
    image_path = product['image_path']
    available_quantity = product['available_quantity']

    # Check if enough stock is available for the selected variation
    if quantity > available_quantity:
        flash(f'Not enough stock available for this variation. Only {available_quantity} items left.')
        return redirect(url_for('product_detail', product_id=product_id))

    # Check if the item is already in the cart for this user
    cursor.execute("""
        SELECT quantity FROM cart 
        WHERE user_id = %s AND product_id = %s AND size = %s AND color = %s
    """, (session['user_id'], product_id, size, color))
    existing_item = cursor.fetchone()

    try:
        if existing_item:
            # Item exists, update the quantity but ensure it doesn't exceed available stock
            new_quantity = existing_item['quantity'] + quantity
            if new_quantity > available_quantity:
                flash(f'You can only add up to {available_quantity} items of this variation to your cart.')
                return redirect(url_for('product_detail', product_id=product_id))
            cursor.execute("""
                UPDATE cart 
                SET quantity = %s 
                WHERE user_id = %s AND product_id = %s AND size = %s AND color = %s
            """, (new_quantity, session['user_id'], product_id, size, color))
        else:
            # Item does not exist, insert it into the cart
            if quantity > available_quantity:
                flash(f'You can only add up to {available_quantity} items of this variation to your cart.')
                return redirect(url_for('product_detail', product_id=product_id))
            cursor.execute("""
                INSERT INTO cart (user_id, product_id, quantity, size, color, price, image_path)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (session['user_id'], product_id, quantity, size, color, product_price, image_path))

        db.commit()  # Commit the changes to the database
        flash('Item added to cart successfully!')
    except Exception as e:
        db.rollback()  # Rollback in case of error
        flash(f'An error occurred while adding the item to your cart. Error: {e}')

    return redirect(url_for('product_detail', product_id=product_id))


@app.route('/checkout', methods=['GET', 'POST'])
def checkout():
    if 'user_id' not in session:
        flash('You need to be logged in to proceed with the checkout.')
        return redirect(url_for('login'))

    user_id = session['user_id']
    cursor = db.cursor(dictionary=True)

    # Fetch user details
    cursor.execute("""
        SELECT first_name, middle_name, last_name, contact_number 
        FROM users WHERE id = %s
    """, (user_id,))
    user_details = cursor.fetchone()

    if not user_details:
        flash('Unable to fetch user details. Please try again later.')
        return redirect(url_for('profile'))

    full_name = f"{user_details['first_name']} {user_details['middle_name']} {user_details['last_name']}".strip()

    # Fetch shipping address
    cursor.execute("""
        SELECT id, region, province, city, barangay, street
        FROM shipping_address WHERE user_id = %s
    """, (user_id,))
    shipping_address = cursor.fetchone()

    if not shipping_address:
        flash('Unable to fetch your shipping address. Please update your profile.')
        return redirect(url_for('profile'))

    # Fetch cart items
    cursor.execute("""
        SELECT c.cart_id, p.product_id, p.name, c.quantity, c.size, c.color, c.price, c.image_path 
        FROM cart c 
        JOIN products p ON c.product_id = p.product_id 
        WHERE c.user_id = %s
    """, (user_id,))
    cart_items = cursor.fetchall()

    if request.method == 'POST':
        if 'place_order' in request.form:
            order_items = []
            total_amount = 0
            selected_cart_ids = request.form.getlist('checkout_items')

            for item in cart_items:
                item_id = item['cart_id']
                quantity = request.form.get(f'quantity_{item_id}', type=int)
                size = request.form.get(f'size_{item_id}')
                color = request.form.get(f'color_{item_id}')

                if str(item_id) in selected_cart_ids and quantity > 0:
                    cursor.execute("""
                        SELECT id, quantity FROM product_variations 
                        WHERE product_id = %s AND size = %s AND color = %s
                    """, (item['product_id'], size, color))
                    variation = cursor.fetchone()

                    if not variation:
                        flash(f"Variation with size {size} and color {color} not found for product {item['name']}.")
                        return redirect(url_for('checkout'))

                    if variation['quantity'] < quantity:
                        flash(f"Not enough stock for {item['name']} in size {size} and color {color}.")
                        return redirect(url_for('checkout'))

                    total_amount += quantity * item['price']
                    order_items.append((
                        item['product_id'], quantity, size, color,
                        item['price'], variation['id']
                    ))

            if not order_items:
                flash('Please select at least one item to place your order.')
                return redirect(url_for('cart'))

            payment_method = request.form.get('payment_method')
            cursor.execute("""
                INSERT INTO orders (user_id, shipping_id, total_amount, payment_method, order_date) 
                VALUES (%s, %s, %s, %s, NOW())
            """, (user_id, shipping_address['id'], total_amount, payment_method))
            order_id = cursor.lastrowid

            # Insert order items with tracking number
            for product_id, quantity, size, color, price, variation_id in order_items:
                tracking_number = f"TRK-{product_id}-{int(datetime.now().timestamp())}"

                cursor.execute("""
                    INSERT INTO order_items (
                        order_id, product_id, quantity, size, color, price, 
                        product_variation_id, tracking_number
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    order_id, product_id, quantity, size, color, price,
                    variation_id, tracking_number
                ))

                cursor.execute("""
                    UPDATE product_variations 
                    SET quantity = quantity - %s 
                    WHERE id = %s
                """, (quantity, variation_id))

            for cart_id in selected_cart_ids:
                cursor.execute("DELETE FROM cart WHERE cart_id = %s AND user_id = %s", (cart_id, user_id))

            db.commit()
            cursor.close()
            return redirect(url_for('order_confirmation', order_id=order_id))

    cursor.close()

    selected_cart_items = []
    if request.method == 'POST' and 'checkout_items' in request.form:
        selected_ids = request.form.getlist('checkout_items')
        for item in cart_items:
            item_id = item['cart_id']
            quantity = request.form.get(f'quantity_{item_id}', type=int)
            size = request.form.get(f'size_{item_id}')
            color = request.form.get(f'color_{item_id}')
            if str(item_id) in selected_ids:
                selected_cart_items.append({
                    'cart_id': item['cart_id'],
                    'product_id': item['product_id'],
                    'name': item['name'],
                    'quantity': quantity,
                    'size': size,
                    'color': color,
                    'price': item['price'],
                    'image': item['image_path']
                })
    else:
        selected_cart_items = cart_items

    total_amount = sum(item['quantity'] * item['price'] for item in selected_cart_items)

    return render_template('checkout.html', 
                           full_name=full_name, 
                           contact_number=user_details['contact_number'], 
                           shipping_address=shipping_address, 
                           order_summary=selected_cart_items, 
                           total_amount=total_amount)


@app.route('/order_confirmation/<int:order_id>')
def order_confirmation(order_id):
    if 'user_id' not in session:
        flash('You need to be logged in to view your order confirmation.')
        return redirect(url_for('login'))

    user_id = session['user_id']
    
    # Fetch order details
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT o.order_id, o.total_amount, o.payment_method, o.order_date, 
               sa.street, sa.barangay, 
               sa.city, sa.province, sa.region,
               CONCAT(u.first_name, ' ', u.middle_name, ' ', u.last_name) AS full_name,
               u.contact_number
        FROM orders o 
        JOIN shipping_address sa ON o.shipping_id = sa.id 
        JOIN users u ON o.user_id = u.id  -- Join with the users table
        WHERE o.order_id = %s AND o.user_id = %s
    """, (order_id, user_id))
    order = cursor.fetchone()

    if not order:
        flash('Order not found.')
        return redirect(url_for('home'))  # Redirect to home if order not found

    # Fetch order items with product variation details (including image)
    cursor.execute("""
        SELECT oi.product_id, oi.quantity, oi.size, oi.price, oi.color, p.name, 
               pv.image_path
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_variations pv ON oi.product_id = pv.product_id 
        AND oi.color = pv.color 
        AND oi.size = pv.size
        WHERE oi.order_id = %s
    """, (order_id,))
    order_items = cursor.fetchall()
    cursor.close()

    # Pass the order details, order items, and user's full name/contact number to the template
    return render_template('order_confirmation.html', order=order, order_items=order_items)


@app.route('/add_shipping_address', methods=['POST'])
def add_shipping_address():
    if 'user_id' not in session:
        flash('You need to be logged in to add a shipping address.')
        return redirect(url_for('login'))  # Redirect to login if user is not logged in

    full_name = request.form['full_name']
    contact_number = request.form['contact_number']
    street = request.form['street']
    barangay = request.form['barangay']
    municipality = request.form['municipality']
    province = request.form['province']
    country = request.form['country']
    user_id = session['user_id']

    try:
        # Insert shipping address into the database
        cursor.execute("""
            INSERT INTO shipping_address (user_id, full_name, contact_number, street, barangay, municipality, province, country)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (user_id, full_name, contact_number, street, barangay, municipality, province, country))

        # Commit the transaction
        db.commit()
        flash('Shipping address added successfully!')

    except Exception as e:
        db.rollback()  # Rollback in case of error
        flash(f'An error occurred while adding the shipping address: {str(e)}')

    return redirect(url_for('checkout'))

@app.route('/user_profile')
def user_profile():
    if 'user_id' not in session:
        flash('You need to be logged in to view your profile.')
        return redirect(url_for('login'))

    user_id = session['user_id']
    cursor = db.cursor(dictionary=True)

    # Fetch user information including profile picture
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()

    # Fetch the user's profile picture from the profile_pictures table
    cursor.execute("""
        SELECT picture_url FROM profile_pictures 
        WHERE user_id = %s ORDER BY uploaded_at DESC LIMIT 1
    """, (user_id,))
    profile_picture = cursor.fetchone()

    profile_picture_url = profile_picture['picture_url'] if profile_picture else '/static/default-profile.jpg'

    cursor.close()

    return render_template(
        'buyer_userprof.html', 
        user=user, 
        profile_picture_url=profile_picture_url
    )

@app.route('/update_profile_picture', methods=['POST'])
def update_profile_picture():
    if 'user_id' not in session:
        flash('You need to be logged in to update your profile picture.')
        return redirect(url_for('login'))

    user_id = session['user_id']
    if 'profile_picture' not in request.files:
        flash('No file part')
        return redirect(url_for('user_profile'))

    file = request.files['profile_picture']

    if file.filename == '':
        flash('No selected file')
        return redirect(url_for('user_profile'))

    if file and allowed_file(file.filename):
        # Fetch the current profile picture from the database
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT picture_url FROM profile_pictures WHERE user_id = %s ORDER BY uploaded_at DESC LIMIT 1
        """, (user_id,))
        current_picture = cursor.fetchone()

        if current_picture:
            # Delete the old profile picture from the static folder
            old_picture_path = current_picture['picture_url']
            if os.path.exists(old_picture_path):
                try:
                    os.remove(old_picture_path)
                except Exception as e:
                    flash(f"Error deleting old profile picture: {e}")
                    return redirect(url_for('user_profile'))
        
        # Generate a new filename for the profile picture
        file_extension = file.filename.rsplit('.', 1)[1].lower()
        filename = str(uuid.uuid4()) + '.' + file_extension
        filepath = os.path.join(app.config['PROFILE_PIC_FOLDER'], filename)
        file.save(filepath)

        # Check if the user already has a profile picture
        if current_picture:
            # Update the picture_url in the database if the user already has a profile picture
            cursor.execute("""
                UPDATE profile_pictures
                SET picture_url = %s, uploaded_at = %s
                WHERE user_id = %s ORDER BY uploaded_at DESC LIMIT 1
            """, (filepath, datetime.now(), user_id))
        else:
            # Insert a new profile picture record if the user does not have one
            cursor.execute("""
                INSERT INTO profile_pictures (user_id, picture_url, uploaded_at)
                VALUES (%s, %s, %s)
            """, (user_id, filepath, datetime.now()))
        
        db.commit()
        cursor.close()

        flash('Profile picture updated successfully!')
        return redirect(url_for('user_profile'))

    flash('Invalid file type. Only image files are allowed.')
    return redirect(url_for('user_profile'))


@app.route('/buyer_orders')
def buyer_orders():
    if 'user_id' not in session:
        flash('You need to be logged in to view your profile.')
        return redirect(url_for('login'))

    user_id = session['user_id']
    cursor = db.cursor(dictionary=True)

    # Fetch user information
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()

    # Fetch order items for the user along with product variation details (color, image_path)
    cursor.execute("""
        SELECT 
            oi.order_item_id, oi.quantity, oi.size, oi.price, oi.order_status, 
            p.product_id, p.name AS product_name, p.image AS product_image, 
            pv.color, pv.image_path, oi.order_id
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id 
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_variations pv ON oi.product_id = pv.product_id 
        AND oi.color = pv.color AND oi.size = pv.size
        WHERE o.user_id = %s
    """, (user_id,))

    order_items = cursor.fetchall()  # Fetch all order items related to the user

    # Fetch order details for the user (for order confirmation)
    cursor.execute(""" 
        SELECT o.order_id, o.total_amount, o.payment_method, o.order_date, 
               sa.street, sa.barangay, 
               sa.city, sa.province, sa.region 
        FROM orders o 
        JOIN shipping_address sa ON o.shipping_id = sa.id 
        WHERE o.user_id = %s
    """, (user_id,))
    orders = cursor.fetchall()  # Fetch all orders for the user

    cursor.close()

    # Pass the user data, order items, and orders to the template
    return render_template('buyer_orders.html', user=user, order_items=order_items, orders=orders)

@app.route('/update_order_status/<int:order_item_id>', methods=['POST'])
def update_order_status(order_item_id):
    if 'user_id' not in session:
        flash('You need to be logged in to change order status.')
        return redirect(url_for('login'))

    user_id = session['user_id']
    cursor = db.cursor()

    # Update the order item status to "Delivered"
    cursor.execute("""
        UPDATE order_items 
        SET order_status = %s 
        WHERE order_item_id = %s AND order_status != 'Delivered' AND EXISTS (
            SELECT 1 FROM orders WHERE order_id = order_items.order_id AND user_id = %s
        )
    """, ('Delivered', order_item_id, user_id))

    db.commit()

    cursor.close()

    flash('Order status updated to Delivered.')
    return redirect(url_for('buyer_orders'))

@app.route('/product_bought')
def product_bought():
    if 'user_id' not in session:
        flash('You need to be logged in to view your seller profile.')
        return redirect(url_for('login'))

    user_id = session['user_id']
    cursor = db.cursor(dictionary=True)

    # Fetch orders belonging to this seller
    cursor.execute("""
        SELECT o.order_id,
            oi.order_item_id,
            oi.quantity,
            oi.order_status,
            oi.rider_id,
            oi.price * oi.quantity AS total_amount,
            p.name AS product_name,
            pv.size,
            pv.image_path AS product_image_variation,
            r.first_name AS rider_first_name,
            r.last_name AS rider_last_name
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        JOIN product_variations pv ON oi.product_variation_id = pv.id
        LEFT JOIN riders r ON oi.rider_id = r.id
        WHERE p.seller_id = %s
        ORDER BY o.order_id DESC
    """, (user_id,))
    orders = cursor.fetchall()

    # Fetch approved riders
    cursor.execute("SELECT id, first_name, last_name FROM riders WHERE status = 'approved'")
    riders = cursor.fetchall()

    cursor.close()
    return render_template('product_bought.html', orders=orders, riders=riders)

@app.route('/update_status', methods=['POST'])
def update_status():
    if 'user_id' not in session:
        flash('You need to be logged in to update the status.')
        return redirect(url_for('login'))

    order_item_id = request.form['order_item_id']
    new_status = request.form['new_status']
    rider_id = request.form.get('rider_id')
    changed_by = session['user_id']
    now = datetime.now()

    if rider_id == '' or rider_id is None:
        rider_id = None
    else:
        rider_id = int(rider_id)

    try:
        with db.cursor(dictionary=True) as cursor:
            # Get current status to avoid duplicate logging
            cursor.execute("SELECT order_status FROM order_items WHERE order_item_id = %s", (order_item_id,))
            result = cursor.fetchone()
            current_status = result['order_status'] if result else None

            # Update only if something changed
            cursor.execute("""
                UPDATE order_items
                SET order_status = %s,
                    rider_id = %s,
                    status_changed_at = %s
                WHERE order_item_id = %s
            """, (new_status, rider_id, now, order_item_id))

            # Log change only if status changed
            if current_status and current_status != new_status:
                cursor.execute("""
                    INSERT INTO order_status_log (order_item_id, status, changed_at, changed_by)
                    VALUES (%s, %s, %s, %s)
                """, (order_item_id, new_status, now, changed_by))

            db.commit()
            flash('Order status and rider updated successfully.')

    except Exception as e:
        db.rollback()
        flash(f'Error updating order: {e}')

    return redirect(url_for('product_bought'))

@app.route('/remove_from_cart/<int:cart_id>', methods=['POST'])
def remove_from_cart(cart_id):
    if 'user_id' not in session:
        flash('You need to be logged in to remove items from your cart.')
        return jsonify({'success': False, 'message': 'User not logged in'})

    # Use the cursor to remove the item from the cart for the logged-in user
    try:
        cursor = db.cursor()
        cursor.execute("DELETE FROM cart WHERE cart_id = %s AND user_id = %s", (cart_id, session['user_id']))
        db.commit()

        if cursor.rowcount > 0:
            return jsonify({'success': True})
        else:
            return jsonify({'success': False, 'message': 'Item not found in your cart.'})

    except Exception as e:
        db.rollback()  # Rollback in case of error
        return jsonify({'success': False, 'message': f'Error: {e}'})

    
@app.route('/products')
def products():
    return render_template('admin.product.html')

@app.route('/admin/archive')
def admin_archive():
    db = get_db_connection()
    
    # Ensure the user is logged in and has admin role
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    try:
        cursor = db.cursor(dictionary=True)
        
        # Execute the query to get only users with 'blocked_until' as None
        cursor.execute("""
            SELECT u.id, u.first_name, u.email, u.status, u.blocked_until, p.picture_url AS profile_picture
            FROM users u
            LEFT JOIN profile_pictures p ON u.id = p.user_id
            WHERE u.status = 'blocked' AND u.blocked_until IS NULL
            ORDER BY u.id DESC
        """)
        
        # Fetch all the results
        blocked_users = cursor.fetchall()

    except mysql.connector.Error as e:
        # Handle database errors
        print(f"Error fetching blocked users: {e}")
        blocked_users = []

    finally:
        cursor.close()
        db.close()

    # Pass the list of users to the template
    return render_template('admin_archive.html', blocked_users=blocked_users)

@app.route('/admin/toggle_blocked_user_status/<int:user_id>', methods=['POST'])
def toggle_blocked_user_status(user_id):
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)  # Ensure dictionary cursor to use keys like 'status'

    try:
        # Query to check if the user exists and retrieve their status
        cursor.execute("SELECT id, status FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()

        if user:
            # Check if the user is currently blocked
            if user['status'] == 'blocked':
                # If blocked, update to active and clear the blocked_until
                cursor.execute("""
                    UPDATE users
                    SET status = 'active', blocked_until = NULL
                    WHERE id = %s
                """, (user_id,))
                db.commit()

                # Flash a success message
                flash('User has been unblocked successfully.', 'success')
            else:
                # If the user is not blocked, notify with a warning
                flash('User is already active.', 'warning')
        else:
            # If the user was not found, notify with an error
            flash('User not found.', 'error')

    except mysql.connector.Error as err:
        # In case of a database error, flash an error message
        flash(f"Database Error: {err}", 'error')

    finally:
        # Close the cursor and connection
        cursor.close()
        db.close()

    # Redirect to the admin archive page to refresh the data
    return redirect(url_for('admin_archive'))


@app.route('/customers')
def customers():
    # Connect to the database
    db = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",  # replace with your actual password
        database="fara"  # replace with your actual database name
    )
    
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    try:
        # Create a cursor object to interact with the database
        cursor = db.cursor(dictionary=True)

        # Fetch recent buyers excluding blocked users where Blocked_Until is None
        cursor.execute("""
            SELECT u.id, u.first_name, u.email, u.status, p.picture_url AS profile_picture
            FROM users u
            LEFT JOIN profile_pictures p ON u.id = p.user_id
            WHERE u.role = 'buyer' 
            AND (u.status != 'blocked' OR u.blocked_until IS NOT NULL)
            ORDER BY u.id DESC LIMIT 5
        """)
        recent_buyers = cursor.fetchall()

        # Fetch recent sellers with shop information and excluding blocked users
        cursor.execute("""
            SELECT u.id, u.first_name, u.email, s.shop_name, s.shop_image, u.status, u.photo
            FROM users u
            LEFT JOIN seller_shops s ON u.id = s.user_id
            WHERE u.role = 'seller' 
            AND (u.status != 'blocked' OR u.blocked_until IS NOT NULL)
            ORDER BY u.id DESC LIMIT 5
        """)
        recent_sellers = cursor.fetchall()

    finally:
        # Ensure the cursor and database connection are closed
        cursor.close()
        db.close()

    # Render the template and pass the buyer and seller data
    return render_template('admin.customers.html', recent_buyers=recent_buyers, recent_sellers=recent_sellers)

# Function to get DB connection
def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",  # Replace with your actual password
        database="fara"  # Replace with your actual database name
    )

# Scheduler Task
def check_blocked_users():
    """Check for users whose block duration has ended and unblock them."""
    db = get_db_connection()  # Correctly get the database connection
    try:
        cursor = db.cursor(dictionary=True)
        cursor.execute(""" 
            SELECT id, status, role, email, blocked_until 
            FROM users 
            WHERE status = 'blocked' AND blocked_until IS NOT NULL
        """)
        blocked_users = cursor.fetchall()

        for user in blocked_users:
            # Check if the block duration has passed
            if user['blocked_until'] < datetime.now():
                # Unblock the user
                cursor.execute("""UPDATE users SET status = 'active', blocked_until = NULL WHERE id = %s""", (user['id'],))
                db.commit()
                send_email_notification(user['email'], action='unblocked')
                with app.app_context():
                    flash(f"User {user['email']} has been unblocked.", 'success')

    except mysql.connector.Error as err:
        print(f"Database error: {err}")
    finally:
        cursor.close()
        db.close()

# Initialize scheduler
scheduler = BackgroundScheduler()
scheduler.add_job(func=check_blocked_users, trigger="interval", hours=1)  # Run the task every hour
scheduler.start()

@app.route('/admin/toggle_user_status/<int:user_id>', methods=['POST'])
def toggle_user_status(user_id):
    db = None
    cursor = None

    try:
        db = get_db_connection()  # Correctly get the database connection
        if db is None:
            flash('Database connection failed.', 'danger')
            return redirect(url_for('customers'))

        cursor = db.cursor(dictionary=True)  # Use the correct db object to get cursor
        cursor.execute("""SELECT id, status, role, email, blocked_until FROM users WHERE id = %s""", (user_id,))
        user = cursor.fetchone()

        if user:
            reason = request.form.get('reason')  # Get the reason for blocking/unblocking
            block_duration = request.form.get('block_duration')  # Block duration

            if user['role'] == 'seller':
                handle_seller_status(cursor, db, user, block_duration, reason)

            elif user['role'] == 'buyer':
                handle_buyer_status(cursor, db, user, block_duration, reason)

        else:
            flash('User not found.', 'danger')

    except mysql.connector.Error as err:
        print(f"Database error: {err}")
        flash('An error occurred while processing the request.', 'danger')

    finally:
        # Ensure cursor and db are not None before attempting to close
        if cursor:
            cursor.close()
        if db:
            db.close()

    return redirect(url_for('customers'))

# Example function to handle a seller's status
def handle_seller_status(cursor, db, user, block_duration, reason):
    """Handle the status of a seller (accept, block, unblock)."""
    if user['status'] == 'pending':
        cursor.execute("""UPDATE users SET status = 'active' WHERE id = %s""", (user['id'],))
        db.commit()
        flash('Seller has been accepted and activated!', 'success')
        send_email_notification(user['email'], action='accepted')

    elif user['status'] == 'active':
        block_user(cursor, db, user, block_duration, reason)

    elif user['status'] == 'blocked':
        cursor.execute("""UPDATE users SET status = 'active', blocked_until = NULL WHERE id = %s""", (user['id'],))
        db.commit()
        flash('Seller has been unblocked and activated!', 'success')
        send_email_notification(user['email'], action='unblocked')

def handle_buyer_status(cursor, db, user, block_duration, reason):
    """Handle the status of a buyer (accept, block, unblock)."""
    
    if user['status'] == 'pending':
        cursor.execute("""UPDATE users SET status = 'active' WHERE id = %s""", (user['id'],))
        db.commit()
        flash('Buyer account has been accepted and activated!', 'success')
        send_email_notification(user['email'], action='accepted')
    
    elif user['status'] == 'active':
        block_user(cursor, db, user, block_duration, reason)
    
    elif user['status'] == 'blocked':
        cursor.execute("""UPDATE users SET status = 'active', blocked_until = NULL WHERE id = %s""", (user['id'],))
        db.commit()
        flash('Buyer account has been unblocked and activated!', 'success')
        send_email_notification(user['email'], action='unblocked')

def block_user(cursor, db, user, block_duration, reason):
    """Block a user (either temporary or permanent)."""
    
    if block_duration == 'permanent':
        # Permanent block: Set 'blocked_until' to NULL
        cursor.execute("""
            UPDATE users 
            SET status = 'blocked', blocked_until = NULL 
            WHERE id = %s
        """, (user['id'],))
        db.commit()
        flash('User has been permanently blocked!', 'success')
        send_email_notification(user['email'], action='blocked', reason=reason)
    else:
        # Temporary block: Validate and ensure block_duration is a valid number
        if block_duration is not None and block_duration.isdigit():  # Check if it's a valid positive number
            block_duration_days = int(block_duration)  # Convert block_duration to an integer
            block_end_date = datetime.now() + timedelta(days=block_duration_days)
            cursor.execute("""
                UPDATE users 
                SET status = 'blocked', blocked_until = %s 
                WHERE id = %s
            """, (block_end_date, user['id']))
            db.commit()
            flash(f'User has been blocked for {block_duration_days} days!', 'success')
            send_email_notification(user['email'], action='blocked', reason=reason, blocked_until=block_end_date)
        else:
            flash('Invalid block duration. Please enter a valid number of days.', 'danger')


def send_email_notification(user_email, action, reason=None, blocked_until=None):
    """Send an email notification regarding the user's account status change."""
    sender_email = "fresdiea@gmail.com"
    sender_password = "rjeb kakc kfjp mxma"  # Make sure to use your app-specific password

    subject, body = '', ''

    if action == 'accepted':
        subject = "Your Seller Account has been Approved!"
        body = """
        Dear Seller,

        Congratulations! Your account has been approved and activated on FARA E-commerce Website.
        You can now start managing your shop and selling your products.

        Best Regards,
        The FARA Team
        """
    elif action == 'blocked':
        subject = "Your Account has been Blocked"
        
        if blocked_until:  # For temporary blocks, send unblock date
            unblock_date = blocked_until.strftime('%B %d, %Y at %I:%M %p')
            duration = (blocked_until - datetime.now()).days
            body = f"""
            Dear User,

            Your account has been blocked due to the following reason: {reason}

            Your account will be restored in {duration} days on {unblock_date}. 

            If you believe this is a mistake, please contact our support team.

            Best Regards,
            The FARA Team
            """
        else:  # Permanent block, no unblock date
            body = f"""
            Dear User,

            Your account has been blocked permanently due to the following reason: {reason}

            If you believe this is a mistake, please contact our support team.

            Best Regards,
            The FARA Team
            """
    elif action == 'unblocked':
        subject = "Your Account has been Unblocked"
        body = """
        Dear User,

        Your account has been unblocked. You can now access your account again.

        Best Regards,
        The FARA Team
        """

    # Create the email message
    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = user_email
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    try:
        # Send the email
        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            text = msg.as_string()
            server.sendmail(sender_email, user_email, text)
    except Exception as e:
        print(f"Error sending email: {e}")

@app.route('/reports')
def reports():
    return render_template('admin.reports.html')

@app.route('/settings')
def settings():
    return render_template('admin.settings.html')

@app.route('/chat/<int:seller_id>', methods=['GET', 'POST'])
def chat(seller_id):
    buyer_id = session.get('user_id')  # Assuming the user is logged in and their ID is in the session

    if not buyer_id:
        flash('You need to be logged in to chat.')
        return redirect(url_for('login'))

    cursor = db.cursor(dictionary=True)
    
    # Fetch existing messages between buyer and seller
    cursor.execute("""
        SELECT * FROM messages
        WHERE (sender_id = %s AND receiver_id = %s) 
        OR (sender_id = %s AND receiver_id = %s)
        ORDER BY timestamp
    """, (buyer_id, seller_id, seller_id, buyer_id))
    messages = cursor.fetchall()

    if request.method == 'POST':
        message = request.form.get('message')
        if message:
            cursor.execute("""
                INSERT INTO messages (sender_id, receiver_id, message)
                VALUES (%s, %s, %s)
            """, (buyer_id, seller_id, message))
            db.commit()
            return redirect(url_for('chat', seller_id=seller_id))

    return render_template('buyer_message.html', messages=messages, seller_id=seller_id)

@app.route('/buyer/chat_overview', methods=['GET'])
def buyer_chat_overview():
    """
    Display a list of all sellers the buyer has interacted with.
    """
    if 'user_id' not in session or session['role'] != 'buyer':
        return redirect(url_for('login'))  # Redirect to login if not a buyer

    buyer_id = session['user_id']

    with db.cursor(dictionary=True) as cursor:
        # Fetch distinct sellers the buyer has communicated with
        cursor.execute("""
            SELECT DISTINCT u.id AS seller_id, u.first_name AS seller_name
            FROM messages m
            JOIN users u ON u.id = m.sender_id OR u.id = m.receiver_id
            WHERE (m.sender_id = %s OR m.receiver_id = %s) AND u.role = 'seller'
        """, (buyer_id, buyer_id))
        sellers = cursor.fetchall()

    return render_template('buyer_chat_overview.html', sellers=sellers)


@app.route('/buyer/chat/<int:seller_id>', methods=['GET', 'POST'])
def buyer_chat(seller_id):
    """
    Display chat history between the buyer and the specified seller, and handle sending messages.
    """
    if 'user_id' not in session or session['role'] != 'buyer':
        return redirect(url_for('login'))  # Redirect to login if not a buyer

    buyer_id = session['user_id']

    if request.method == 'POST':
        # Handle sending a message
        message = request.form['message']

        # Insert the message into the database
        with db.cursor() as cursor:
            cursor.execute("""
                INSERT INTO messages (sender_id, receiver_id, message, timestamp)
                VALUES (%s, %s, %s, NOW())
            """, (buyer_id, seller_id, message))
            db.commit()

        flash('Message sent successfully!', 'success')
        return redirect(url_for('buyer_chat', seller_id=seller_id))

    # Fetch chat history between buyer and seller
    with db.cursor(dictionary=True) as cursor:
        cursor.execute("""
            SELECT m.message, m.sender_id, m.timestamp, u.first_name AS sender_name
            FROM messages m
            JOIN users u ON m.sender_id = u.id
            WHERE (m.sender_id = %s AND m.receiver_id = %s)
               OR (m.sender_id = %s AND m.receiver_id = %s)
            ORDER BY m.timestamp ASC
        """, (buyer_id, seller_id, seller_id, buyer_id))
        messages = cursor.fetchall()

    # Fetch seller's name and ID
    with db.cursor(dictionary=True) as cursor:
        cursor.execute("SELECT id, first_name FROM users WHERE id = %s", (seller_id,))
        seller = cursor.fetchone()

    if not seller:
        flash('Seller not found.', 'error')
        return redirect(url_for('buyer_chat_overview'))

    return render_template('buyer_chat.html', messages=messages, seller=seller)

@app.route('/seller/chat', methods=['GET'])
def seller_chat_overview():
    if 'user_id' not in session or session['role'] != 'seller':
        flash('You must be logged in as a seller to access this page.', 'error')
        return redirect(url_for('login'))  # Redirect to login if not a seller

    seller_id = session['user_id']

    try:
        with db.cursor(dictionary=True) as cursor:
            # Query to get the list of buyers the seller has interacted with and the last message
            cursor.execute("""
                SELECT u.id AS buyer_id, u.first_name AS buyer_name, 
                       MAX(m.timestamp) AS last_message_time, 
                       MAX(m.message) AS last_message
                FROM messages m
                JOIN users u ON (u.id = m.sender_id OR u.id = m.receiver_id)
                WHERE (m.sender_id = %s AND m.receiver_id != %s) OR 
                      (m.receiver_id = %s AND m.sender_id != %s)
                GROUP BY u.id, u.first_name
                ORDER BY last_message_time DESC
            """, (seller_id, seller_id, seller_id, seller_id))
            buyer_chats = cursor.fetchall()

        return render_template('seller_chat_overview.html', buyer_chats=buyer_chats)

    except Exception as e:
        flash(f"An error occurred while fetching chat history: {str(e)}", 'error')
        return redirect(url_for('seller_homepage'))


@app.route('/seller/chat/<int:buyer_id>', methods=['GET', 'POST'])
def seller_chat(buyer_id):
    """
    Display chat history between the seller and the specified buyer and handle sending messages.
    """
    if 'user_id' not in session or session['role'] != 'seller':
        flash('You must be logged in as a seller to access this page.', 'error')
        return redirect(url_for('login'))  # Redirect to login if not a seller

    seller_id = session['user_id']

    if request.method == 'POST':
        # Handle sending a message
        message = request.form['message']

        if not message.strip():  # Prevent sending empty messages
            flash('Message cannot be empty.', 'error')
            return redirect(url_for('seller_chat', buyer_id=buyer_id))

        try:
            with db.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO messages (sender_id, receiver_id, message, timestamp)
                    VALUES (%s, %s, %s, NOW())
                """, (seller_id, buyer_id, message))
                db.commit()

            flash('Message sent successfully!', 'success')
            return redirect(url_for('seller_chat', buyer_id=buyer_id))

        except Exception as e:
            flash(f"An error occurred while sending the message: {str(e)}", 'error')
            return redirect(url_for('seller_chat', buyer_id=buyer_id))

    try:
        # Fetch chat history between seller and buyer
        with db.cursor(dictionary=True) as cursor:
            cursor.execute("""
                SELECT m.message, m.sender_id, m.timestamp, u.first_name AS sender_name
                FROM messages m
                JOIN users u ON m.sender_id = u.id
                WHERE (m.sender_id = %s AND m.receiver_id = %s)
                   OR (m.sender_id = %s AND m.receiver_id = %s)
                ORDER BY m.timestamp ASC
            """, (seller_id, buyer_id, buyer_id, seller_id))
            messages = cursor.fetchall()

        # Fetch buyer's name for the chat title
        with db.cursor(dictionary=True) as cursor:
            cursor.execute("SELECT first_name FROM users WHERE id = %s", (buyer_id,))
            buyer = cursor.fetchone()

        if not buyer:
            flash('Buyer not found.', 'error')
            return redirect(url_for('seller_chat_overview'))

        return render_template('seller_chat.html', messages=messages, buyer=buyer)

    except Exception as e:
        flash(f"An error occurred while fetching the chat history: {str(e)}", 'error')
        return redirect(url_for('seller_chat_overview'))

@app.route('/sales_report', methods=['GET'])
def sales_report():
    # Retrieve optional start_date and end_date from the query parameters
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')

    # Define the query
    query = """
        SELECT p.name, oi.quantity, oi.price AS unit_price, 
               (oi.quantity * oi.price) AS total, o.order_date AS date_sold
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        JOIN orders o ON oi.order_id = o.order_id
    """
    
    # Add date filtering if provided
    if start_date and end_date:
        query += " WHERE o.order_date BETWEEN %s AND %s"
        params = (start_date, end_date)
    else:
        params = ()

    # Execute the query
    cursor = db.cursor(dictionary=True)
    cursor.execute(query, params)
    sales_data = cursor.fetchall()

    # Calculate total sales
    total_sales = sum(sale['total'] for sale in sales_data) if sales_data else 0

    # Render the sales report template
    return render_template('sales_report.html', sales_data=sales_data, total_sales=total_sales)


def send_reset_email(to_email, reset_code):
    sender_email = "fresdiea@gmail.com"  # Replace with your email
    sender_password = "rjeb kakc kfjp mxma"  # Replace with your email password or app-specific password

    subject = "Password Reset Request"
    body = f"Your password reset code is: {reset_code}\n\nUse this code to reset your password."

    # Create message object
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = to_email
    message["Subject"] = subject
    message.attach(MIMEText(body, "plain"))

    try:
        # Connect to Gmail's SMTP server
        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.starttls()  # Upgrade the connection to secure
            server.login(sender_email, sender_password)  # Login to the SMTP server
            server.sendmail(sender_email, to_email, message.as_string())  # Send the email
            print(f"Email sent to {to_email} with reset code: {reset_code}")  # Debugging statement
    except Exception as e:
        print(f"Error sending email: {e}")
        return False
    return True

@app.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    db = None  # Initialize db as None to avoid UnboundLocalError
    try:
        if request.method == 'POST':
            email = request.form['email']

            # Establish connection to MySQL database
            db = mysql.connector.connect(
                host='localhost',  # Your DB host
                user='root',       # Your DB username
                password='',       # Your DB password
                database='fara'    # Your database name
            )

            # Check if connection is successful
            if db.is_connected():
                cursor = db.cursor()

                # Query to find the user by email
                cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
                user = cursor.fetchone()

                if user:
                    # Generate a unique reset code and expiration time
                    reset_code = str(uuid.uuid4().int)[:6]  # Generate a 6-digit code
                    expiration = datetime.utcnow() + timedelta(hours=1)  # Code valid for 1 hour

                    # Update user record with the reset code and expiration time
                    cursor.execute(
                        "UPDATE users SET reset_token = %s, reset_token_expiration = %s WHERE email = %s",
                        (reset_code, expiration, email)
                    )
                    db.commit()  # Commit changes to the database

                    # Send email with the reset code
                    if send_reset_email(email, reset_code):
                        flash('Password reset code has been sent to your email.', 'success')
                        return redirect(url_for('verify_reset_code', token=reset_code))  # Redirect to code verification page
                    else:
                        flash('Failed to send the password reset email. Please try again later.', 'danger')

                else:
                    flash('Email address not found.', 'danger')
            else:
                flash('Failed to connect to the database. Please try again later.', 'danger')

    except mysql.connector.Error as db_error:
        flash(f'Database error: {db_error}', 'danger')

    except Exception as e:
        flash(f'An unexpected error occurred: {e}', 'danger')

    finally:
        # Ensure the database connection is properly closed if it was opened
        if db and db.is_connected():
            db.close()

    return render_template('forgot_password.html')

@app.route('/verify-reset-code/<token>', methods=['GET', 'POST'])
def verify_reset_code(token):
    db = None
    cursor = None
    try:
        # Establish connection to MySQL database
        db = mysql.connector.connect(
            host='localhost',   # Your DB host
            user='root',        # Your DB username
            password='',        # Your DB password
            database='fara'     # Your database name
        )

        cursor = db.cursor()

        # Check if the token exists and is not expired
        cursor.execute("SELECT * FROM users WHERE reset_token = %s", (token,))
        user = cursor.fetchone()

        if user:
            reset_token_expiration = user[14]  # Assuming reset_token_expiration is at index 14
            if reset_token_expiration > datetime.utcnow():
                # If the request method is POST, allow the user to reset their password
                if request.method == 'POST':
                    verification_code = request.form['verification_code']
                    if verification_code == token:  # Match verification code with token
                        flash('Verification successful. You can now reset your password.', 'success')
                        return redirect(url_for('reset_password', token=token))  # Redirect to reset password form
                    else:
                        flash('Invalid verification code.', 'danger')
                        return redirect(url_for('forgot_password'))  # Redirect to forgot password if invalid code

                return render_template('verify_reset_code.html', token=token)  # Render the verification page
            else:
                flash('The password reset code has expired.', 'danger')
                return redirect(url_for('forgot_password'))

        else:
            flash('The password reset code is invalid.', 'danger')
            return redirect(url_for('forgot_password'))

    except mysql.connector.Error as db_error:
        flash(f'Database error: {db_error}', 'danger')

    except Exception as e:
        flash(f'An unexpected error occurred: {e}', 'danger')

    finally:
        # Ensure cursor and connection are closed properly
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

    return render_template('verify_reset_code.html', token=token)


@app.route('/reset-password/<token>', methods=['GET', 'POST'])
def reset_password(token):
    db = None
    cursor = None
    try:
        # Establish connection to MySQL database
        db = mysql.connector.connect(
            host='localhost',   # Your DB host
            user='root',        # Your DB username
            password='',        # Your DB password
            database='fara'     # Your database name
        )

        cursor = db.cursor()

        # Check if the token exists and is not expired
        cursor.execute("SELECT * FROM users WHERE reset_token = %s", (token,))
        user = cursor.fetchone()

        if user:
            reset_token_expiration = user[14]  # Ensure this is the correct index for reset_token_expiration
            if reset_token_expiration > datetime.utcnow():
                # If the request method is POST, allow the user to reset their password
                if request.method == 'POST':
                    new_password = request.form['new_password']

                    # Directly store the password (not hashed)
                    cursor.execute(""" 
                        UPDATE users 
                        SET password = %s, reset_token = NULL, reset_token_expiration = NULL 
                        WHERE reset_token = %s
                    """, (new_password, token))
                    db.commit()  # Commit the changes

                    flash('Your password has been reset successfully!', 'success')
                    return redirect(url_for('login'))  # Redirect to login page after password reset

                return render_template('reset_password.html', token=token)

            else:
                flash('The password reset code has expired.', 'danger')
                return redirect(url_for('forgot_password'))  # Redirect back to the forgot password page

        else:
            flash('The password reset code is invalid.', 'danger')
            return redirect(url_for('forgot_password'))  # Invalid token, redirect to forgot password page

    except mysql.connector.Error as db_error:
        flash(f'Database error: {db_error}', 'danger')

    except Exception as e:
        flash(f'An unexpected error occurred: {e}', 'danger')

    finally:
        # Ensure cursor and connection are closed properly
        if cursor:
            cursor.close()
        if db and db.is_connected():
            db.close()

    return render_template('reset_password.html', token=token)

@app.route('/rider_register', methods=['GET', 'POST'])
def rider_register():
    if request.method == 'POST':
        first_name = request.form['first_name']
        last_name = request.form['last_name']
        middle_name = request.form.get('middle_name')
        contact_number = request.form['contact_number']
        birthday = request.form['birthday']
        email = request.form['email']
        password = request.form['password']
        confirm_password = request.form['confirm_password']
        vehicle_type = request.form['vehicle_type']

        # Handle file upload
        if 'photo' not in request.files:
            flash("No file part!", "danger")
            return redirect(url_for('rider_register'))

        file = request.files['photo']

        if file.filename == '':
            flash("No selected file!", "danger")
            return redirect(url_for('rider_register'))

        if not allowed_file(file.filename):
            flash("File type not allowed! Upload a valid image or PDF.", "danger")
            return redirect(url_for('rider_register'))

        # Secure the filename and create a unique name
        original_filename = secure_filename(file.filename)
        file_extension = os.path.splitext(original_filename)[1]  # Get the file extension
        unique_filename = f"{uuid.uuid4()}{file_extension}"  # Generate a unique filename
        photo_path = os.path.join(app.config['RIDER_LICENSE_FOLDER'], unique_filename)

        # Save the file to the designated path
        file.save(photo_path)

        # Save only the relative path in the database
        relative_photo_path = f'rider_licenses/{unique_filename}'

        # Insert into MySQL database (default status = pending)
        sql = """INSERT INTO riders 
                 (first_name, last_name, middle_name, contact_number, birthday, email, password, vehicle_type, license_photo, status) 
                 VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'pending')"""
        values = (first_name, last_name, middle_name, contact_number, birthday, email, password, vehicle_type, relative_photo_path)

        try:
            cursor.execute(sql, values)
            db.commit()
            flash("Rider registration submitted! Waiting for admin approval.", "success")
            return redirect(url_for('rider_login'))
        except mysql.connector.IntegrityError:
            flash("Error: Duplicate contact number or email!", "danger")
            db.rollback()
        except Exception as e:
            flash(f"Database error: {str(e)}", "danger")
            db.rollback()

    return render_template('rider_reg.html')


@app.route('/rider_login', methods=['GET', 'POST'])
def rider_login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        cursor.execute("SELECT id, status FROM riders WHERE email = %s AND password = %s", (email, password))
        rider = cursor.fetchone()

        if rider:
            rider_id, status = rider
            if status == "approved":
                session['rider_id'] = rider_id
                flash("Login successful!", "success")
                return redirect(url_for('rider_dashboard'))
            else:
                flash("Your account is still pending approval or has been declined.", "danger")
        else:
            flash("Invalid email or password.", "danger")

    return render_template('rider_log.html')

@app.route('/admin_riders')
def admin_riders():
    cursor.execute("SELECT id, first_name, last_name, contact_number, email, vehicle_type, license_photo, status FROM riders")
    riders = cursor.fetchall()
    
    rider_list = []
    for rider in riders:
        rider_list.append({
            "id": rider[0],
            "first_name": rider[1],
            "last_name": rider[2],
            "contact_number": rider[3],
            "email": rider[4],
            "vehicle_type": rider[5],
            "license_photo": rider[6],
            "status": rider[7]
        })

    return render_template('admin_rider.html', riders=rider_list)


def send_email(to_email, subject, body):
    sender_email = "fresdiea@gmail.com"  # Replace with your email
    sender_password = "rjeb kakc kfjp mxma"  # Use an app-specific password for Gmail

    # Create the email message
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = to_email
    message["Subject"] = subject
    message.attach(MIMEText(body, "plain"))

    try:
        # Connect to Gmail's SMTP server
        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.starttls()  # Secure the connection
            server.login(sender_email, sender_password)  # Login
            server.sendmail(sender_email, to_email, message.as_string())  # Send the email
            print(f"Email sent to {to_email}")  # Debugging
    except Exception as e:
        print(f"Error sending email: {e}")
        return False
    return True

@app.route('/approve_rider/<int:rider_id>')
def approve_rider(rider_id):
    cursor.execute("SELECT email FROM riders WHERE id = %s", (rider_id,))
    rider = cursor.fetchone()

    if rider:
        rider_email = rider[0]
        cursor.execute("UPDATE riders SET status = 'approved' WHERE id = %s", (rider_id,))
        db.commit()

        # Send approval email
        subject = "Rider Account Approved"
        body = "Congratulations! Your rider account has been approved. You can now log in."
        send_email(rider_email, subject, body)

        flash("Rider approved successfully!", "success")
    return redirect(url_for('admin_riders'))

@app.route('/decline_rider/<int:rider_id>')
def decline_rider(rider_id):
    cursor.execute("SELECT email FROM riders WHERE id = %s", (rider_id,))
    rider = cursor.fetchone()

    if rider:
        rider_email = rider[0]
        cursor.execute("UPDATE riders SET status = 'declined' WHERE id = %s", (rider_id,))
        db.commit()

        # Send decline email
        subject = "Rider Account Declined"
        body = "Unfortunately, your rider account has been declined. Please contact support for further assistance."
        send_email(rider_email, subject, body)

        flash("Rider declined!", "danger")
    return redirect(url_for('admin_riders'))

@app.route('/rider_dashboard')
def rider_dashboard():
    if 'rider_id' not in session:
        return redirect(url_for('rider_login'))  # Redirect if not logged in

    cursor = db.cursor(dictionary=True)

    # Count active deliveries (orders with status 'to ship')
    query = "SELECT COUNT(*) AS active_deliveries FROM order_items WHERE order_status = 'to ship'"
    cursor.execute(query)
    result = cursor.fetchone()
    active_deliveries = result['active_deliveries'] if result else 0

    cursor.close()

    return render_template('rider_dashboard.html', active_deliveries=active_deliveries)

@app.route('/active_deliveries')
def active_deliveries():
    if 'rider_id' not in session:
        return redirect(url_for('rider_login'))  # Redirect if not logged in

    cursor = db.cursor(dictionary=True)

    query = """
        SELECT oi.order_item_id, oi.order_id, oi.quantity, 
               oi.size, oi.color, oi.price, oi.order_status, 
               p.name AS product_name, pv.image_path,
               u.first_name, u.middle_name, u.last_name,
               sa.region, sa.province, sa.city, sa.barangay, sa.street
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_variations pv ON oi.product_variation_id = pv.id
        JOIN orders o ON oi.order_id = o.order_id
        JOIN users u ON o.user_id = u.id
        LEFT JOIN shipping_address sa ON o.user_id = sa.user_id
        WHERE oi.order_status = 'to ship'
    """

    cursor.execute(query)
    orders = cursor.fetchall()
    cursor.close()

    return render_template('active_deliveries.html', orders=orders)

@app.route('/claim_delivery/<int:order_item_id>', methods=['POST'])
def claim_delivery(order_item_id):
    if 'rider_id' not in session:
        return redirect(url_for('rider_login'))

    rider_id = session['rider_id']
    cursor = db.cursor()

    # Update order status, assign rider, and set shipping fee
    query = """
        UPDATE order_items 
        SET order_status = 'To Receive', rider_id = %s, shipping_fee = 59.00
        WHERE order_item_id = %s AND order_status = 'to ship'
    """
    cursor.execute(query, (rider_id, order_item_id))
    db.commit()
    cursor.close()

    return redirect(url_for('active_deliveries'))

@app.route('/ongoing_deliveries')
def ongoing_deliveries():
    if 'rider_id' not in session:
        return redirect(url_for('rider_login'))

    rider_id = session['rider_id']
    cursor = db.cursor(dictionary=True)

    query = """
        SELECT oi.order_item_id, oi.order_id, oi.quantity, 
               oi.size, oi.color, oi.price, oi.order_status, 
               p.name AS product_name, pv.image_path,
               u.first_name, u.middle_name, u.last_name,
               sa.region, sa.province, sa.city, sa.barangay, sa.street
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_variations pv ON oi.product_variation_id = pv.id
        JOIN orders o ON oi.order_id = o.order_id
        JOIN users u ON o.user_id = u.id
        LEFT JOIN shipping_address sa ON o.user_id = sa.user_id
        WHERE oi.order_status = 'To Receive' AND oi.rider_id = %s
    """

    cursor.execute(query, (rider_id,))
    orders = cursor.fetchall()
    cursor.close()

    return render_template('ongoing_deliveries.html', orders=orders)

@app.route('/unclaim_order', methods=['POST'])
def unclaim_order():
    if 'rider_id' not in session:
        return redirect(url_for('rider_login'))

    order_item_id = request.form['order_item_id']

    cursor = db.cursor()
    update_query = """
        UPDATE order_items 
        SET order_status = 'To ship', rider_id = NULL
        WHERE order_item_id = %s AND rider_id = %s
    """
    cursor.execute(update_query, (order_item_id, session['rider_id']))
    db.commit()
    cursor.close()

    flash("Order unclaimed successfully!", "success")
    return redirect(url_for('ongoing_deliveries'))

@app.route('/rider_logout')
def rider_logout():
    session.pop('rider_id', None)  # Remove rider session
    return redirect(url_for('rider_login'))  # Redirect to login page

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)