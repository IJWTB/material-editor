if (SERVER) then
	util.AddNetworkString("Materialize")
end

advMats = advMats or {}
advMats.stored = advMats.stored or {}

function advMats:GetStored()
	return self.stored
end

function advMats:Set(ent, texture, data)
	if (SERVER) then
		net.Start("Materialize")
		net.WriteEntity(ent)
		net.WriteString(texture)
		net.WriteTable(data)
		net.Broadcast()

		ent.MaterialData = {
			texture = texture,
			ScaleX = data.ScaleX or 1,
			ScaleY = data.ScaleY or 1,
			OffsetX = data.OffsetX or 0,
			OffsetY = data.OffsetY or 0,
			UseNoise = data.UseNoise or false,
			NoiseTexture = data.NoiseTexture or "detail/noise_detail_01",
			NoiseScaleX = data.NoiseScaleX or 1,
			NoiseScaleY = data.NoiseScaleY or 1,
			NoiseOffsetX = data.NoiseOffsetX or 0,
			NoiseOffsetY = data.NoiseOffsetY or 0,
		}

		if (texture == nil or texture == "") then
			if (IsValid(ent)) then
				ent:SetMaterial("")
				ent.MaterialData = nil -- clear the table so it doesn't get reapplied
				duplicator.ClearEntityModifier(ent, "MaterialData") -- clear modifier
			end

			return
		end

		texture = texture:lower()
		texture = string.Trim(texture)
		local uid = texture .. "+" .. (data.ScaleX or 1) .. "+" .. (data.ScaleY or 1) .. "+" .. (data.OffsetX or 0) .. "+" .. (data.OffsetY or 0)

		if (data.UseNoise) then
			uid = uid .. (data.NoiseTexture or "detail/noise_detail_01") .. "+" .. (data.NoiseScaleX or 1) .. "+" .. (data.NoiseScaleY or 1) .. "+" .. (data.NoiseOffsetX or 0) .. "+" .. (data.NoiseOffsetY or 0)
		end

		uid = uid:gsub("%.", "-")

		ent:SetMaterial("!" .. uid)

		duplicator.StoreEntityModifier(ent, "MaterialData", ent.MaterialData)
	else
		if (texture == nil or texture == "") then
			if (IsValid(ent)) then
				ent:SetMaterial("")
			end

			return
		end

		data = data or {}
		data.UseNoise = data.UseNoise or false
		data.ScaleX = data.ScaleX or 1
		data.ScaleY = data.ScaleY or 1
		data.OffsetX = data.OffsetX or 0
		data.OffsetY = data.OffsetY or 0
		data.NoiseTexture = data.NoiseTexture or "detail/noise_detail_01"
		data.NoiseScaleX = data.NoiseScaleX or 1
		data.NoiseScaleY = data.NoiseScaleY or 1
		data.NoiseOffsetX = data.NoiseOffsetX or 0
		data.NoiseOffsetY = data.NoiseOffsetY or 0

		texture = texture:lower()
		texture = string.Trim(texture)

		local tempMat = Material(texture)

		if (string.find(texture, "../", 1, true) or string.find(texture, "pp/", 1, true)) then
			return
		end

		local uid = texture .. "+" .. data.ScaleX .. "+" .. data.ScaleY .. "+" .. data.OffsetX .. "+" .. data.OffsetY

		if (data.UseNoise) then
			uid = uid .. (data.NoiseTexture or "detail/noise_detail_01") .. "+" .. (data.NoiseScaleX or 1) .. "+" .. (data.NoiseScaleY or 1) .. "+" .. (data.NoiseOffsetX or 0) .. "+" .. (data.NoiseOffsetY or 0)
		end

		uid = uid:gsub("%.", "-")

		if (!self.stored[uid]) then

			local matTable = {
				["$basetexture"] = tempMat:GetName(),
				["$basetexturetransform"] = "center .5 .5 scale " .. (1 / data.ScaleX) .. " " .. (1 / data.ScaleY) .. " rotate 0 translate " .. data.OffsetX .. " " .. data.OffsetY,
				["$vertexalpha"] = 0,
				["$vertexcolor"] = 1
			}

			for k, v in pairs(data) do
				if (k:sub(1, 1) == "$") then
					matTable[k] = v
				end
			end

			if (data.UseNoise) then
				matTable["$detail"] = data.NoiseTexture
			end

			if (file.Exists("materials/" .. texture .. "_normal.vtf", "GAME")) then
				matTable["$bumpmap"] = texture .. "_normal"
				matTable["$bumptransform"] = "center .5 .5 scale " .. (1 / data.ScaleX) .. " " .. (1 / data.ScaleY) .. " rotate 0 translate " .. data.OffsetX .. " " .. data.OffsetY
			end

			local matrix = Matrix()
			matrix:Scale(Vector(1 / data.ScaleX, 1 / data.ScaleY, 1))
			matrix:Translate(Vector(data.OffsetX, data.OffsetY, 0))

			local noiseMatrix = Matrix()
			noiseMatrix:Scale(Vector(1 / data.NoiseScaleX, 1 / data.NoiseScaleY, 1))
			noiseMatrix:Translate(Vector(data.NoiseOffsetX, data.NoiseOffsetY, 0))

			self.stored[uid] = CreateMaterial(uid, "VertexLitGeneric", matTable)
			self.stored[uid]:SetTexture("$basetexture", tempMat:GetTexture("$basetexture"))
			self.stored[uid]:SetMatrix("$basetexturetransform", matrix)
			self.stored[uid]:SetMatrix("$detailtexturetransform", noiseMatrix)
		end

		ent.MaterialData = {
			texture = texture,
			ScaleX = data.ScaleX or 1,
			ScaleY = data.ScaleY or 1,
			OffsetX = data.OffsetX or 0,
			OffsetY = data.OffsetY or 0,
			UseNoise = data.UseNoise or false,
			NoiseTexture = data.NoiseTexture or "detail/noise_detail_01",
			NoiseScaleX = data.NoiseScaleX or 1,
			NoiseScaleY = data.NoiseScaleY or 1,
			NoiseOffsetX = data.NoiseOffsetX or 0,
			NoiseOffsetY = data.NoiseOffsetY or 0,
		}

		ent:SetMaterial("!" .. uid)
	end
end

if (CLIENT) then
	net.Receive("Materialize", function()
		local ent = net.ReadEntity()
		local texture = net.ReadString()
		local data = net.ReadTable()

		if (IsValid(ent)) then
			advMats:Set(ent, texture, data)
		end
	end)
else
	hook.Add("PlayerInitialSpawn", "AdvMatSet", function(player)
		for k, v in pairs(ents.GetAll()) do
			if (IsValid(v) and v.MaterialData) then
				net.Start("Materialize")
				net.WriteEntity(v)
				net.WriteString(v.MaterialData.texture)
				net.WriteTable(v.MaterialData)
				net.Send(player)
			end
		end
	end)
end

duplicator.RegisterEntityModifier("MaterialData", function(player, entity, data)
	advMats:Set(entity, data.texture, data)
end)
