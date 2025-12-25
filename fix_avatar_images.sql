-- Update Avatars with reliable free URLs (Flaticon direct links often expire or block hotlinking)
-- We will use generic placeholders or reliable publicly hosted images.

UPDATE avatars
SET image_url = CASE name
    WHEN 'الأمير الصغير' THEN 'https://img.icons8.com/color/480/little-prince.png'
    WHEN 'رائد الفضاء' THEN 'https://img.icons8.com/color/480/astronaut.png'
    WHEN 'البطل الخارق' THEN 'https://img.icons8.com/color/480/spiderman-head.png'
    WHEN 'القطة السعيدة' THEN 'https://img.icons8.com/color/480/cat.png'
    WHEN 'النمر القوي' THEN 'https://img.icons8.com/color/480/tiger.png'
    WHEN 'الأميرة' THEN 'https://img.icons8.com/color/480/princess.png'
    WHEN 'الكلب الوفي' THEN 'https://img.icons8.com/color/480/dog.png'
    WHEN 'القط الشجاع' THEN 'https://img.icons8.com/color/480/garbage-truck.png' -- Generic cool icon
    WHEN 'الباندا الهادئ' THEN 'https://img.icons8.com/color/480/panda.png'
    WHEN 'القرد الذكي' THEN 'https://img.icons8.com/color/480/monkey.png'
    WHEN 'الثعلب السريع' THEN 'https://img.icons8.com/color/480/fox.png'
    WHEN 'النمر الجريء' THEN 'https://img.icons8.com/color/480/tiger.png'
    ELSE 'https://img.icons8.com/color/480/user.png' -- Fallback
END
WHERE image_url LIKE '%flaticon%' OR image_url IS NULL OR image_url = '';
