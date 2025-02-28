from flask import Flask, render_template, request
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import MinMaxScaler
from sklearn.impute import SimpleImputer

# Initialize Flask app
app = Flask(__name__)




# Load the dataset
divorce_data = pd.read_csv("divorces_2000-2015_translated.csv")

# Handle infinite values
divorce_data.replace([np.inf, -np.inf], np.nan, inplace=True)

# Impute missing numerical values
numerical_cols = ['Age_partner_man', 'Age_partner_woman', 'Monthly_income_partner_man_peso', 
                  'Monthly_income_partner_woman_peso', 'Marriage_duration', 'Marriage_duration_months', 'Num_Children']
imputer = SimpleImputer(strategy='mean')
divorce_data[numerical_cols] = imputer.fit_transform(divorce_data[numerical_cols])

# Impute missing categorical values (e.g., for education and employment status)
categorical_cols = ['Level_of_education_partner_man', 'Level_of_education_partner_woman', 
                    'Employment_status_partner_man', 'Employment_status_partner_woman']
categorical_imputer = SimpleImputer(strategy='most_frequent')
divorce_data[categorical_cols] = categorical_imputer.fit_transform(divorce_data[categorical_cols])

divorce_data.dropna(subset = ['DOB_partner_man', 'DOB_partner_woman'], inplace=True)

# Preprocess Data (same as before)
divorce_data['Income_diff'] = abs(divorce_data['Monthly_income_partner_man_peso'] - divorce_data['Monthly_income_partner_woman_peso'])
divorce_data['Age_gap'] = abs(divorce_data['Age_partner_man'] - divorce_data['Age_partner_woman'])

# Convert Education Level to Numeric
education_map = {'PRIMARIA': 1, 'SECUNDARIA': 2, 'PREPARATORIA': 3, 'PROFESIONAL': 4}
divorce_data['Education_man'] = divorce_data['Level_of_education_partner_man'].map(education_map)
divorce_data['Education_woman'] = divorce_data['Level_of_education_partner_woman'].map(education_map)

# Create Feature Matrix (X) and Target Vector (y)
X = divorce_data[['Income_diff', 'Age_gap', 'Marriage_duration', 'Num_Children', 'Education_man', 'Education_woman']]
y = divorce_data['Type_of_divorce'].apply(lambda x: 1 if x == 'Necesario' else 0)  # Divorce = 1, No Divorce = 0

# Handle any potential infinite or NaN values in X
X = X.replace([np.inf, -np.inf], np.nan)
X = X.fillna(X.mean())  # Replace NaN with the mean of each column

# Normalize Features
scaler = MinMaxScaler()
X_normalized = scaler.fit_transform(X)

# Check for NaN or infinite values after scaling
if np.any(np.isnan(X_normalized)) or np.any(np.isinf(X_normalized)):
    print("Warning: NaN or infinite values found in X_normalized")

# Train Random Forest Classifier
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_normalized, y)

# Predict Divorce Probability
def predict_divorce_probability(data):
    features = np.array([
        abs(data['income_man'] - data['income_woman']),
        abs(data['age_man'] - data['age_woman']),
        data['marriage_duration'],
        data['children'],
        education_map.get(data['education_man'], 0),
        education_map.get(data['education_woman'], 0)
    ]).reshape(1, -1)

    # Normalize and Predict
    features_normalized = scaler.transform(features)
    probability = model.predict_proba(features_normalized)[0][1] * 100  # Probability of Divorce
    return round(min(max(probability, 0), 100), 2)  # Keep within 0-100%

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        # Get input data from the form
        income_man = int(request.form['income_man'])
        income_woman = int(request.form['income_woman'])
        age_man = int(request.form['age_man'])
        age_woman = int(request.form['age_woman'])
        education_man = request.form['education_man']
        education_woman = request.form['education_woman']
        marriage_duration = int(request.form['marriage_duration'])
        children = int(request.form['children'])

        # Prepare data for prediction
        data = {
            'income_man': income_man,
            'income_woman': income_woman,
            'age_man': age_man,
            'age_woman': age_woman,
            'education_man': education_man,
            'education_woman': education_woman,
            'marriage_duration': marriage_duration,
            'children': children
        }

        # Predict divorce probability
        probability = predict_divorce_probability(data)
        return render_template("index.html", probability=probability)

    return render_template("index.html", probability=None)

if __name__ == "__main__":
    app.run(debug=True)
