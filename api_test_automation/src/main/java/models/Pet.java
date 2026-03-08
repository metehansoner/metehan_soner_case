package models;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public class Pet {
    private Long id;
    private Category category;
    private String name;
    private List<String> photoUrls;
    private List<Tag> tags;
    private String status;

    public Pet() {}

    private Pet(Builder builder) {
        this.id = builder.id;
        this.category = builder.category;
        this.name = builder.name;
        this.photoUrls = builder.photoUrls;
        this.tags = builder.tags;
        this.status = builder.status;
    }

    public static Builder builder() {
        return new Builder();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public Category getCategory() { return category; }
    public void setCategory(Category category) { this.category = category; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public List<String> getPhotoUrls() { return photoUrls; }
    public void setPhotoUrls(List<String> photoUrls) { this.photoUrls = photoUrls; }
    
    public List<Tag> getTags() { return tags; }
    public void setTags(List<Tag> tags) { this.tags = tags; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public static class Builder {
        private Long id;
        private Category category;
        private String name;
        private List<String> photoUrls;
        private List<Tag> tags;
        private String status;

        public Builder id(Long id) { this.id = id; return this; }
        public Builder category(Category category) { this.category = category; return this; }
        public Builder name(String name) { this.name = name; return this; }
        public Builder photoUrls(List<String> photoUrls) { this.photoUrls = photoUrls; return this; }
        public Builder tags(List<Tag> tags) { this.tags = tags; return this; }
        public Builder status(String status) { this.status = status; return this; }
        
        public Pet build() { return new Pet(this); }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Category {
        private Long id;
        private String name;

        public Category() {}

        private Category(Builder builder) {
            this.id = builder.id;
            this.name = builder.name;
        }

        public static Builder builder() {
            return new Builder();
        }

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public static class Builder {
            private Long id;
            private String name;

            public Builder id(Long id) { this.id = id; return this; }
            public Builder name(String name) { this.name = name; return this; }
            
            public Category build() { return new Category(this); }
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Tag {
        private Long id;
        private String name;

        public Tag() {}

        private Tag(Builder builder) {
            this.id = builder.id;
            this.name = builder.name;
        }

        public static Builder builder() {
            return new Builder();
        }

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public static class Builder {
            private Long id;
            private String name;

            public Builder id(Long id) { this.id = id; return this; }
            public Builder name(String name) { this.name = name; return this; }
            
            public Tag build() { return new Tag(this); }
        }
    }
}
