-- Seed common car brands and models
INSERT INTO public.car_brands (company, model, category) VALUES
-- Toyota
('Toyota', 'Camry', 'car'),
('Toyota', 'Corolla', 'car'),
('Toyota', 'RAV4', 'car'),
('Toyota', 'Highlander', 'car'),
('Toyota', 'Prius', 'car'),

-- Honda
('Honda', 'Civic', 'car'),
('Honda', 'Accord', 'car'),
('Honda', 'CR-V', 'car'),
('Honda', 'Pilot', 'car'),

-- Ford
('Ford', 'F-150', 'car'),
('Ford', 'Mustang', 'car'),
('Ford', 'Explorer', 'car'),
('Ford', 'Escape', 'car'),

-- Chevrolet
('Chevrolet', 'Silverado', 'car'),
('Chevrolet', 'Malibu', 'car'),
('Chevrolet', 'Equinox', 'car'),
('Chevrolet', 'Tahoe', 'car'),

-- BMW
('BMW', '3 Series', 'car'),
('BMW', '5 Series', 'car'),
('BMW', 'X3', 'car'),
('BMW', 'X5', 'car'),

-- Mercedes-Benz
('Mercedes-Benz', 'C-Class', 'car'),
('Mercedes-Benz', 'E-Class', 'car'),
('Mercedes-Benz', 'GLC', 'car'),
('Mercedes-Benz', 'GLE', 'car'),

-- Audi
('Audi', 'A4', 'car'),
('Audi', 'A6', 'car'),
('Audi', 'Q5', 'car'),
('Audi', 'Q7', 'car'),

-- Kia
('Kia', 'K5', 'car'),
('Kia', 'Forte', 'car'),
('Kia', 'Sportage', 'car'),
('Kia', 'Sorento', 'car'),
('Kia', 'Telluride', 'car'),

-- Hyundai
('Hyundai', 'Elantra', 'car'),
('Hyundai', 'Sonata', 'car'),
('Hyundai', 'Tucson', 'car'),
('Hyundai', 'Santa Fe', 'car'),
('Hyundai', 'Palisade', 'car'),

-- Nissan
('Nissan', 'Altima', 'car'),
('Nissan', 'Sentra', 'car'),
('Nissan', 'Rogue', 'car'),
('Nissan', 'Pathfinder', 'car'),

-- Volkswagen
('Volkswagen', 'Jetta', 'car'),
('Volkswagen', 'Passat', 'car'),
('Volkswagen', 'Tiguan', 'car'),
('Volkswagen', 'Atlas', 'car'),

-- Mazda
('Mazda', 'Mazda3', 'car'),
('Mazda', 'Mazda6', 'car'),
('Mazda', 'CX-5', 'car'),
('Mazda', 'CX-9', 'car'),

-- Subaru
('Subaru', 'Impreza', 'car'),
('Subaru', 'Legacy', 'car'),
('Subaru', 'Outback', 'car'),
('Subaru', 'Forester', 'car')

ON CONFLICT DO NOTHING;
