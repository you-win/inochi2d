/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors:
        Luna Nielsen
        Asahi Lina
*/
module inochi2d.math.transform;
public import inochi2d.math;
import inochi2d.fmt.serialize;

/**
    A transform
*/
struct Transform {
private:
    @Ignore
    mat4 trs = mat4.identity;

    @Ignore
    mat4 translation_ = mat4.identity;

    @Ignore
    mat4 rotation_ = mat4.identity;

    @Ignore
    mat4 scale_ = mat4.identity;

    @Ignore
    mat4 rotationInv = mat4.identity;

    @Ignore
    bool rotationInvDirty = false;

    @Ignore
    vec3 translationCache = vec3(0, 0, 0);

    @Ignore
    vec3 rotationCache = vec3(0, 0, 0);

    @Ignore
    vec2 scaleCache = vec2(1, 1);

    mat4 getRotationInv() {
        if (rotationInvDirty) {
            rotationInv = quat.euler_rotation(this.rotation.x, this.rotation.y, this.rotation.z).inverse().to_matrix!(4, 4);
            rotationInvDirty = false;
        }
        return rotationInv;
    }

public:

    /**
        The translation of the transform
    */
    vec3 translation = vec3(0, 0, 0);

    /**
        The rotation of the transform
    */
    vec3 rotation = vec3(0, 0, 0);//; = quat.identity;

    /**
        The scale of the transform
    */
    vec2 scale = vec2(1, 1);

    /**
        Locks rotation on the X axis
    */
    bool lockRotationX = false;

    /**
        Locks rotation on the Y axis
    */
    bool lockRotationY = false;
    
    /**
        Locks rotation on the Z axis
    */
    bool lockRotationZ = false;

    /**
        Sets the locking value for all rotation axies
    */
    void lockRotation(bool value) { lockRotationX = lockRotationY = lockRotationZ = value; }

    /**
        Locks translation on the X axis
    */
    bool lockTranslationX = false;

    /**
        Locks translation on the Y axis
    */
    bool lockTranslationY = false;
    
    /**
        Locks translation on the Z axis
    */
    bool lockTranslationZ = false;

    /**
        Sets the locking value for all translation axies
    */
    void lockTranslation(bool value) { lockTranslationX = lockTranslationY = lockTranslationZ = value; }

    /**
        Locks scale on the X axis
    */
    bool lockScaleX = false;

    /**
        Locks scale on the Y axis
    */
    bool lockScaleY = false;

    /**
        Locks all scale axies
    */
    void lockScale(bool value) { lockScaleX = lockScaleY = value; }

    /**
        Whether the transform should snap to pixels
    */
    bool pixelSnap = false;

    /**
        Initialize a transform
    */
    this(vec3 translation, vec3 rotation = vec3(0), vec2 scale = vec2(1, 1)) {
        this.translation = translation;
        this.rotation = rotation;
        this.scale = scale;
    }

    /**
        Returns the result of 2 transforms multiplied together
    */
    Transform opBinary(string op : "*")(Transform other) {
        Transform tnew;

        //
        //  ROTATION
        //

        quat rot = quat.from_matrix(mat3(this.rotation_ * other.rotation_));

        // Handle rotation locks
        if (!lockRotationX) tnew.rotation.x = rot.roll;
        else tnew.rotation.x = this.rotation.x;
        
        if (!lockRotationY) tnew.rotation.y = rot.pitch;
        else tnew.rotation.y = this.rotation.y;

        if (!lockRotationZ) tnew.rotation.z = rot.yaw;
        else tnew.rotation.z = this.rotation.z;

        //
        //  SCALE
        //

        // Handle scale locks
        vec2 scale = vec2(this.scale_ * vec4(other.scale, 1, 1));
        if (!lockScaleX) tnew.scale.x = scale.x;
        if (!lockScaleY) tnew.scale.y = scale.y;

        //
        //  TRANSLATION
        //
        mat4 otherScaleInv = mat4.scaling(1 / other.scale.x, 1 / other.scale.y, 1);

        // Calculate new TRS
        vec3 trans = vec3(
            // We want to support parts being placed correctly even if they're rotation or scale locked
            // therefore we need to apply the worldspace rotation and scale here
            // That has been pre-calculated above.
            // Do note we also multiply by its inverse, this is so that the rotations and scaling doesn't
            // start stacking up weirdly causing cascadingly more extreme transformation.
            other.scale_ * other.rotation_ * this.translation_ * other.getRotationInv() * otherScaleInv *

            // Also our local translation
            vec4(other.translation, 1)
        );

        // Handle translation
        tnew.translation.x = pixelSnap ? round(trans.x) : trans.x;
        tnew.translation.y = pixelSnap ? round(trans.y) : trans.y;
        tnew.translation.z = pixelSnap ? round(trans.z) : trans.z;
        tnew.update();

        return tnew;
    }

    /**
        Gets the matrix for this transform
    */
    @Ignore
    mat4 matrix() {
        return trs;
    }

    /**
        Updates the internal matrix of this transform
    */
    void update() {
        bool recalc = false;

        if (translation != translationCache) {
            translation_ = mat4.translation(translation);
            recalc = true;
            translationCache = translation;
        }
        if (rotation != rotationCache) {
            rotation_ = quat.euler_rotation(this.rotation.x, this.rotation.y, this.rotation.z).to_matrix!(4, 4);
            rotationInvDirty = true;
            recalc = true;
            rotationCache = rotation;
        }
        if (scale != scaleCache) {
            scale_ = mat4.scaling(scale.x, scale.y, 1);
            recalc = true;
            scaleCache = scale;
        }

        if (recalc)
            trs = translation_ * rotation_ * scale_;
    }

    void clear() {
        translation = vec3(0);
        rotation = vec3(0);
        scale = vec2(1, 1);
    }

    @Ignore
    string toString() {
        import std.format : format;
        return "%s,\n%s,\n%s\n%s".format(trs.toPrettyString, translation.toString, rotation.toString, scale.toString);
    }

    void serialize(S)(ref S serializer) {
        auto state = serializer.objectBegin();
            serializer.putKey("trans");
            translation.serialize(serializer);

            serializer.putKey("rot");
            rotation.serialize(serializer);

            if (lockRotationX || lockRotationY || lockRotationZ) {
                serializer.putKey("rot_lock");
                serializer.serializeValue([lockRotationX, lockRotationY, lockRotationZ]);
            }

            serializer.putKey("scale");
            scale.serialize(serializer);

            if (lockScaleX || lockScaleY) {
                serializer.putKey("scale_lock");
                serializer.serializeValue([lockScaleX, lockScaleY]);
            }

        serializer.objectEnd(state);
    }

    SerdeException deserializeFromFghj(Fghj data) {
        translation.deserialize(data["trans"]);
        rotation.deserialize(data["rot"]);
        scale.deserialize(data["scale"]);
        
        if (data["rot_lock"] != Fghj.init) {
            bool[] states;
            data["rot_lock"].deserializeValue(states);

            this.lockRotationX = states[0];
            this.lockRotationY = states[1];
            this.lockRotationZ = states[2];
        }
        
        if (data["scale_lock"] != Fghj.init) {
            bool[] states;
            data["scale_lock"].deserializeValue(states);
            this.lockScaleX = states[0];
            this.lockScaleY = states[1];
        }
        return null;
    }
}
/**
    A 2D transform;
*/
struct Transform2D {
private:
    @Ignore
    mat3 trs;

public:
    /**
        Translate
    */
    vec2 translation;
    /**
        Scale
    */
    vec2 scale;
    
    /**
        Rotation
    */
    float rotation;

    /**
        Gets the matrix for this transform
    */
    mat3 matrix() {
        return trs;
    }

    /**
        Updates the internal matrix of this transform
    */
    void update() {
        mat3 translation_ = mat3.translation(vec3(translation, 0));
        mat3 rotation_ = mat3.zrotation(rotation);
        mat3 scale_ = mat3.scaling(scale.x, scale.y, 1);
        trs =  translation_ * rotation_ * scale_;
    }

}