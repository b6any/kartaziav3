-- INSERT SAMPLE CARDS
insert into cards (name, image_url, price, xp_reward, category, description) values
('Roblox 10\$', 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Roblox_Logo_2022.svg/320px-Roblox_Logo_2022.svg.png', 37.50, 100, 'Games', 'بطاقة روبلوكس بقيمة 10 دولار - 800 روبوكس'),
('Roblox 25\$', 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Roblox_Logo_2022.svg/320px-Roblox_Logo_2022.svg.png', 93.75, 250, 'Games', 'بطاقة روبلوكس بقيمة 25 دولار - 2000 روبوكس'),
('PlayStation 20\$', 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Playstation_logo_colour.svg/320px-Playstation_logo_colour.svg.png', 75.00, 200, 'Games', 'بطاقة ستور بلايستيشن سعودي 20 دولار'),
('Fortnite 1000 V-Bucks', 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/Fortnite_F_lettermark_logo.png/320px-Fortnite_F_lettermark_logo.png', 35.00, 100, 'Games', '1000 في باكس للعبة فورتنايت'),
('Amazon 50 SAR', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Amazon_logo.svg/320px-Amazon_logo.svg.png', 50.00, 50, 'Shopping', 'بطاقة أمازون السعودية 50 ريال'),
('Noon 100 SAR', 'https://upload.wikimedia.org/wikipedia/commons/a/a9/Amazon_logo.svg', 100.00, 100, 'Shopping', 'بطاقة تسوق نون بقيمة 100 ريال');

-- INSERT SAMPLE CODES (Linked to the cards we just created)
-- Note: In real life you would match the exact UUIDs. 
-- For this script to work simply, we will use a DO block to look them up.

DO $$
DECLARE
  v_roblox10 uuid;
  v_ps20 uuid;
BEGIN
  -- Get IDs of cards we just inserted
  select id into v_roblox10 from cards where name = 'Roblox 10\$' limit 1;
  select id into v_ps20 from cards where name = 'PlayStation 20\$' limit 1;

  -- Insert Codes for Roblox 10$
  if v_roblox10 is not null then
    insert into codes (card_id, code_value, status) values
    (v_roblox10, 'RBX-1111-2222-3333', 'available'),
    (v_roblox10, 'RBX-4444-5555-6666', 'available'),
    (v_roblox10, 'RBX-7777-8888-9999', 'available');
  end if;

  -- Insert Codes for PlayStation 20$
  if v_ps20 is not null then
    insert into codes (card_id, code_value, status) values
    (v_ps20, 'PSN-AAAA-BBBB-CCCC', 'available'),
    (v_ps20, 'PSN-DDDD-EEEE-FFFF', 'available');
  end if;

END $$;
